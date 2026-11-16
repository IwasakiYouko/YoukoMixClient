import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:riverpod/riverpod.dart';

import '../helpers/app_paths.dart';
import '../helpers/preferences.dart';

Profile _profile(int id, String label) => Profile(
  id: id,
  label: label,
  autoUpdateDuration: Duration.zero,
  extendType: ExtendType.standard,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database testDatabase;
  late Directory home;

  setUpAll(() async {
    await mockPreferences({'version': 1});
    await AppLocalizations.load(const Locale('en'));
    home = Directory.systemTemp.createTempSync('flclash-backup-action-');
    await useAppPaths(home);
  });

  tearDownAll(() {
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  setUp(() {
    testDatabase = Database(NativeDatabase.memory());
    database = testDatabase;
  });

  tearDown(() async {
    await testDatabase.close();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer()..listen(configProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }

  BackupAction actionOf(ProviderContainer container) =>
      container.read(backupActionProvider.notifier);

  Map<String, Object?> configMapOf(ProviderContainer container) =>
      jsonDecode(jsonEncode(container.read(configProvider).toJson()))
          as Map<String, Object?>;

  group('backup and restore round trip', () {
    late Directory kept;

    setUp(() {
      kept = Directory.systemTemp.createTempSync('flclash-backup-kept-');
      addTearDown(() => kept.deleteSync(recursive: true));
    });

    Set<String> workDirs() => home
        .listSync()
        .map((entity) => basename(entity.path))
        .where((name) => name.startsWith('backup'))
        .toSet();

    Future<String> backupToKept(BackupAction action) async {
      final keptPath = join(kept.path, 'kept.zip');
      final delivered = await action.backup((archivePath) async {
        File(archivePath).copySync(keptPath);
        return true;
      });
      expect(delivered, isTrue);
      return keptPath;
    }

    test(
      'restores scripts and settings while stripping profile YAMLs and rows',
      () async {
        await testDatabase.profilesDao.putAll([
          _profile(9, 'Rogue').toCompanion(0),
        ]);
        final profileFile = File(await appPath.getProfilePath('9'))
          ..createSync(recursive: true)
          ..writeAsStringSync('proxies: []');
        final script = Script(
          id: 5,
          label: 'My script',
          lastUpdateTime: DateTime(2026),
        );
        await testDatabase.scriptsDao.putAll([script.toCompanion()]);
        final scriptFile = File(await appPath.getScriptPath('5'))
          ..createSync(recursive: true)
          ..writeAsStringSync('function main(c){return c;}');

        final source = buildContainer();
        source.read(excludeSSIDsProvider.notifier).value = ['home-wifi'];
        final archivePath = await backupToKept(actionOf(source));

        await testDatabase.delete(testDatabase.profiles).go();
        await testDatabase.delete(testDatabase.scripts).go();
        profileFile.deleteSync();
        scriptFile.deleteSync();

        final target = buildContainer();
        final restored = await actionOf(
          target,
        ).restore(RestoreOption.all, (_) async => archivePath);

        expect(restored, isTrue);
        expect(await testDatabase.profilesDao.query().get(), isEmpty);
        expect(profileFile.existsSync(), isFalse);
        final restoredScripts = await testDatabase.scriptsDao.query().get();
        expect(restoredScripts.map((s) => s.label), ['My script']);
        expect(scriptFile.readAsStringSync(), 'function main(c){return c;}');
        expect(target.read(excludeSSIDsProvider), ['home-wifi']);
        expect(workDirs(), isEmpty);
      },
    );

    test('brings back the attachments of local modules and cleans the '
        'rest', () async {
      final module = MitmModule(
        id: 9,
        name: 'Mine',
        resources: const {'own.json': 'own.json'},
        lastUpdateTime: DateTime(2026),
      );
      await testDatabase.mitmModulesDao.putAll([module.toCompanion()]);
      File(join(home.path, 'mitm', 'modules', module.fileName))
        ..createSync(recursive: true)
        ..writeAsStringSync('[Map Local]\n^https://a data="own.json"\n');
      final resources = join(home.path, 'mitm', 'resources');
      final own = File(join(resources, 'own.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');
      final archivePath = await backupToKept(actionOf(buildContainer()));

      own.deleteSync();
      final stale = File(join(resources, 'stale.json'))..writeAsStringSync('');
      final target = buildContainer();
      final restored = await actionOf(
        target,
      ).restore(RestoreOption.all, (_) async => archivePath);

      expect(restored, isTrue);
      expect(own.readAsStringSync(), '{}');
      expect(stale.existsSync(), isFalse);
    });

    test('removes the work directory when delivery fails', () async {
      final container = buildContainer();

      await expectLater(
        actionOf(
          container,
        ).backup((_) async => throw const SocketException('offline')),
        throwsA(isA<SocketException>()),
      );

      expect(workDirs(), isEmpty);
    });

    test('a cancelled fetch changes nothing', () async {
      final container = buildContainer();

      final restored = await actionOf(
        container,
      ).restore(RestoreOption.all, (_) async => null);

      expect(restored, isFalse);
    });

    test('an unreadable archive is reported and changes nothing', () async {
      await testDatabase.profilesDao.putAll([
        _profile(youkomixManagedProfileId, 'Managed').toCompanion(0),
      ]);
      final bogus = File(join(kept.path, 'bogus.zip'))
        ..writeAsStringSync('not a zip');
      final container = buildContainer();

      await expectLater(
        actionOf(container).restore(RestoreOption.all, (_) async => bogus.path),
        throwsA(
          isA<MessageException>().having(
            (error) => error.message,
            'message',
            currentAppLocalizations.invalidBackupFile,
          ),
        ),
      );

      final stored = await testDatabase.profilesDao.query().get();
      expect(stored.map((item) => item.label), ['Managed']);
      expect(workDirs(), isEmpty);
    });

    test('removes the staging an earlier version left behind', () async {
      final legacyArchive = File(join(home.path, 'backup.zip'))
        ..writeAsStringSync('stale');
      final legacyStaging = Directory(join(home.path, 'restore'))..createSync();
      final container = buildContainer();

      await actionOf(container).restore(RestoreOption.all, (_) async => null);

      expect(legacyArchive.existsSync(), isFalse);
      expect(legacyStaging.existsSync(), isFalse);
    });
  });

  group('applyRestore enforces strict subscription boundary', () {
    test('ignores profiles and custom proxies carried by an archive', () async {
      final container = buildContainer();

      await actionOf(container).applyRestore(
        MigrationData(
          profiles: [_profile(99, 'Injected third-party')],
          customProxies: const [
            CustomProxy(id: 1, definition: {'name': 'HK', 'type': 'ss'}),
          ],
        ),
        RestoreOption.all,
      );

      expect(await testDatabase.profilesDao.query().get(), isEmpty);
      expect(await testDatabase.customProxiesDao.query().get(), isEmpty);
    });

    test(
      'an override restore keeps managed profile #1 and drops unmanaged profiles',
      () async {
        final container = buildContainer();
        await testDatabase.profilesDao.putAll([
          _profile(youkomixManagedProfileId, 'Managed').toCompanion(0),
          _profile(99, 'Rogue').toCompanion(1),
        ]);
        container
            .read(appSettingProvider.notifier)
            .update(
              (state) =>
                  state.copyWith(restoreStrategy: RestoreStrategy.override),
            );

        await actionOf(container).applyRestore(
          MigrationData(
            profiles: [_profile(77, 'From backup')],
            scripts: [
              Script(id: 1, label: 'S1', lastUpdateTime: DateTime(2026)),
            ],
          ),
          RestoreOption.all,
        );

        final stored = await testDatabase.profilesDao.query().get();
        expect(stored.map((item) => item.id), [youkomixManagedProfileId]);
        expect(stored.map((item) => item.label), ['Managed']);
      },
    );

    test('a restore drops the cache of a provider it replaced', () async {
      const dropped = ClashProvider(
        id: 5,
        label: 'Dropped',
        url: 'https://example.com/dropped.yaml',
      );
      const kept = ClashProvider(id: 6, label: 'Kept');
      await testDatabase.clashProvidersDao.putAll(
        [dropped, kept].map((item) => item.toCompanion()),
      );
      for (final path in [
        await dropped.path,
        await dropped.compiledPath,
        await kept.path,
        await kept.compiledPath,
      ]) {
        File(path).createSync(recursive: true);
      }
      final container = buildContainer();
      container
          .read(appSettingProvider.notifier)
          .update(
            (state) =>
                state.copyWith(restoreStrategy: RestoreStrategy.override),
          );

      await actionOf(container).applyRestore(
        const MigrationData(clashProviders: [kept]),
        RestoreOption.onlyProfiles,
      );

      expect(File(await dropped.path).existsSync(), isFalse);
      expect(File(await dropped.compiledPath).existsSync(), isFalse);
      expect(File(await kept.path).existsSync(), isTrue);
      expect(File(await kept.compiledPath).existsSync(), isFalse);
    });

    test('rows that fail to restore take their files back out', () async {
      final replaced = File(await appPath.getScriptPath('41'))
        ..createSync(recursive: true)
        ..writeAsStringSync('current');
      final added = File(await appPath.getScriptPath('42'));
      final staging = Directory.systemTemp.createTempSync('flclash-staging-');
      addTearDown(() => staging.deleteSync(recursive: true));
      for (final id in [41, 42]) {
        File(BackupEntries.resolve(staging.path, BackupEntries.script(id)))
          ..createSync(recursive: true)
          ..writeAsStringSync('from backup');
      }
      await testDatabase.customStatement(
        'CREATE TRIGGER refuse_scripts BEFORE INSERT ON scripts '
        "BEGIN SELECT RAISE(ABORT, 'refused'); END",
      );

      await expectLater(
        actionOf(buildContainer()).applyRestore(
          MigrationData(
            scripts: [
              Script(id: 41, label: 'One', lastUpdateTime: DateTime(2026)),
              Script(id: 42, label: 'Two', lastUpdateTime: DateTime(2026)),
            ],
          ),
          RestoreOption.onlyProfiles,
          stagingDirPath: staging.path,
        ),
        throwsA(anything),
      );

      expect(replaced.readAsStringSync(), 'current');
      expect(added.existsSync(), isFalse);
    });
  });

  group('applyRestore writes the settings providers', () {
    test(
      'restores settings providers while preserving currentProfileId',
      () async {
        final source = buildContainer();
        source
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(autoLaunch: true));
        source.read(currentProfileIdProvider.notifier).value = 42;
        source
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith(mixedPort: 7899));
        final configMap = configMapOf(source);

        final target = buildContainer();
        target.read(currentProfileIdProvider.notifier).value =
            youkomixManagedProfileId;
        await actionOf(
          target,
        ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

        expect(target.read(currentProfileIdProvider), youkomixManagedProfileId);
        expect(target.read(appSettingProvider).autoLaunch, isTrue);
        expect(target.read(patchClashConfigProvider).mixedPort, 7899);
      },
    );

    test('keeps the bound WebDAV account when the backup has none', () async {
      final configMap = configMapOf(buildContainer());
      const dav = DAVProps(uri: 'https://dav.example', user: 'me');
      final target = buildContainer();
      target.read(davSettingProvider.notifier).value = dav;

      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(davSettingProvider), dav);
    });

    test('keeps the picked apps when the backup lists none', () async {
      final configMap = configMapOf(buildContainer());
      const picked = AccessControlProps(
        enable: true,
        mode: AccessControlMode.acceptSelected,
        acceptList: ['com.example.browser'],
      );
      final target = buildContainer();
      target
          .read(vpnSettingProvider.notifier)
          .update((state) => state.copyWith(accessControlProps: picked));

      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(vpnSettingProvider).accessControlProps, picked);
    });

    test('takes the apps a backup lists from another phone', () async {
      const listed = AccessControlProps(
        enable: true,
        rejectList: ['com.example.bank'],
      );
      final source = buildContainer();
      source
          .read(vpnSettingProvider.notifier)
          .update((state) => state.copyWith(accessControlProps: listed));
      final configMap = configMapOf(source);
      final target = buildContainer();
      target
          .read(vpnSettingProvider.notifier)
          .update(
            (state) => state.copyWith(
              accessControlProps: const AccessControlProps(
                acceptList: ['com.example.browser'],
              ),
            ),
          );

      await actionOf(
        target,
      ).applyRestore(MigrationData(configMap: configMap), RestoreOption.all);

      expect(target.read(vpnSettingProvider).accessControlProps, listed);
    });
  });
}
