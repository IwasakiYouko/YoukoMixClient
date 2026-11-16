import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_paths.dart';
import '../helpers/test_profiles.dart';

class _MockCoreHandlerInterface extends Mock implements CoreHandlerInterface {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory home;
  late Database testDb;
  late _MockCoreHandlerInterface core;
  late ProviderContainer container;

  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
    home = Directory.systemTemp.createTempSync('youkomix-profiles-action-');
    await useAppPaths(home);
  });

  tearDownAll(() {
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  setUp(() {
    testDb = Database(NativeDatabase.memory());
    database = testDb;
    core = _MockCoreHandlerInterface();
    when(() => core.validateConfig(any())).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await testDb.close();
  });

  ProviderContainer buildContainer([List<Profile> initial = const []]) {
    final c = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles(initial)),
        coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
      ],
    );
    addTearDown(c.dispose);
    globalState.container = c;
    return c;
  }

  group('saveManagedProfile', () {
    test(
      'saves managed profile #1, parses subscription header, and purges rogue profiles',
      () async {
        const rogue = Profile(
          id: 99,
          label: 'Rogue',
          type: ProfileType.url,
          url: 'https://rogue.example.com/sub',
          autoUpdateDuration: Duration(hours: 6),
        );
        final rogueFile = File(await appPath.getProfilePath('99'))
          ..createSync(recursive: true)
          ..writeAsStringSync('proxies: []');

        container = buildContainer([rogue]);
        container.listen(currentProfileIdProvider, (_, _) {});

        final yamlBytes = Uint8List.fromList(
          utf8.encode('proxies:\n  - {name: HK-01, type: ss}\n'),
        );
        final saved = await container
            .read(profilesActionProvider.notifier)
            .saveManagedProfile(
              bytes: yamlBytes,
              label: '人间之里 · 专属订阅',
              subscriptionInfo: SubscriptionInfo.formHString(
                'upload=1024; download=2048; total=10240; expire=1900000000',
              ),
              autoUpdateDuration: const Duration(hours: 12),
            );

        expect(saved.id, youkomixManagedProfileId);
        expect(saved.label, '人间之里 · 专属订阅');
        expect(saved.type, ProfileType.file);
        expect(saved.url, isEmpty);
        expect(saved.autoUpdateDuration, const Duration(hours: 12));
        expect(saved.subscriptionInfo?.upload, 1024);
        expect(saved.subscriptionInfo?.download, 2048);
        expect(saved.subscriptionInfo?.total, 10240);
        expect(saved.subscriptionInfo?.expire, 1900000000);
        expect(
          container.read(currentProfileIdProvider),
          youkomixManagedProfileId,
        );
        expect(container.read(profilesProvider).map((p) => p.id), [
          youkomixManagedProfileId,
        ]);
        expect(rogueFile.existsSync(), isFalse);
        verify(() => core.validateConfig(any())).called(1);
      },
    );

    test('preserves selectedMap and unfoldSet across refreshes', () async {
      const existing = Profile(
        id: youkomixManagedProfileId,
        label: '人间之里',
        type: ProfileType.file,
        autoUpdateDuration: Duration(hours: 6),
        selectedMap: {'Proxy': 'JP-01'},
        unfoldSet: {'Proxy'},
        currentGroupName: 'Proxy',
      );
      container = buildContainer([existing]);
      container.listen(currentProfileIdProvider, (_, _) {});

      final updated = await container
          .read(profilesActionProvider.notifier)
          .saveManagedProfile(
            bytes: Uint8List.fromList(utf8.encode('proxies: []\n')),
            label: '人间之里 · 更新',
            subscriptionInfo: const SubscriptionInfo(),
          );

      expect(updated.selectedMap, {'Proxy': 'JP-01'});
      expect(updated.unfoldSet, {'Proxy'});
      expect(updated.currentGroupName, 'Proxy');
    });

    test('rejects invalid YAML when core validation returns error', () async {
      when(
        () => core.validateConfig(any()),
      ).thenAnswer((_) async => 'invalid proxy configuration');
      container = buildContainer();

      await expectLater(
        container
            .read(profilesActionProvider.notifier)
            .saveManagedProfile(
              bytes: Uint8List.fromList(utf8.encode('bad: yaml')),
              label: 'Broken',
              subscriptionInfo: const SubscriptionInfo(),
            ),
        throwsA(anything),
      );
      expect(container.read(profilesProvider), isEmpty);
    });
  });

  group('purgeUnmanagedProfiles and clearAllProfiles', () {
    test('purgeUnmanagedProfiles keeps only managed profile', () async {
      const managed = Profile(
        id: youkomixManagedProfileId,
        label: 'Managed',
        autoUpdateDuration: Duration(hours: 6),
      );
      const other = Profile(
        id: 42,
        label: 'ThirdParty',
        autoUpdateDuration: Duration(hours: 6),
      );
      container = buildContainer([managed, other]);
      container.listen(currentProfileIdProvider, (_, _) {});
      container.read(currentProfileIdProvider.notifier).value = 42;

      await container
          .read(profilesActionProvider.notifier)
          .purgeUnmanagedProfiles();

      expect(container.read(profilesProvider).map((p) => p.id), [
        youkomixManagedProfileId,
      ]);
      expect(
        container.read(currentProfileIdProvider),
        youkomixManagedProfileId,
      );
    });

    test(
      'clearAllProfiles removes managed profile and resets current id',
      () async {
        const managed = Profile(
          id: youkomixManagedProfileId,
          label: 'Managed',
          autoUpdateDuration: Duration(hours: 6),
        );
        final file =
            File(
                await appPath.getProfilePath(
                  youkomixManagedProfileId.toString(),
                ),
              )
              ..createSync(recursive: true)
              ..writeAsStringSync('proxies: []');

        container = buildContainer([managed]);
        container.listen(currentProfileIdProvider, (_, _) {});
        container.read(currentProfileIdProvider.notifier).value =
            youkomixManagedProfileId;

        await container
            .read(profilesActionProvider.notifier)
            .clearAllProfiles();

        expect(container.read(profilesProvider), isEmpty);
        expect(container.read(currentProfileIdProvider), isNull);
        expect(file.existsSync(), isFalse);
      },
    );
  });
}
