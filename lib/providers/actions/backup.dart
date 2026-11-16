part of '../action.dart';

typedef BackupDelivery = Future<bool> Function(String archivePath);

typedef BackupFetch = Future<String?> Function(String downloadPath);

@Riverpod(keepAlive: true)
class BackupAction extends _$BackupAction {
  @override
  void build() {}

  Future<bool> backup(BackupDelivery deliver) {
    return _withWorkDir((workDir) async {
      return deliver(await _createArchive(workDir));
    });
  }

  Future<bool> restore(RestoreOption option, BackupFetch fetch) {
    return _withWorkDir((workDir) async {
      final archivePath = await fetch(join(workDir, 'download.zip'));
      if (archivePath == null) {
        return false;
      }
      final stagingDirPath = join(workDir, 'staging');
      final MigrationData data;
      try {
        data = await restoreTask((
          archivePath: archivePath,
          stagingDirPath: stagingDirPath,
        ));
      } on BackupException catch (e) {
        throw MessageException(switch (e.failure) {
          BackupFailure.invalid => currentAppLocalizations.invalidBackupFile,
          BackupFailure.newerVersion =>
            currentAppLocalizations.backupFromNewerVersion,
        });
      }
      await applyRestore(data, option, stagingDirPath: stagingDirPath);
      return true;
    });
  }

  Future<bool> _withWorkDir(Future<bool> Function(String workDir) run) async {
    final workDir = Directory(join(await appPath.tempPath, 'backup$uniqueId'));
    await workDir.create(recursive: true);
    try {
      return await run(workDir.path);
    } finally {
      await workDir.safeDelete(recursive: true);
      await _discardLegacyStaging();
    }
  }

  Future<void> _discardLegacyStaging() async {
    final homeDirPath = await appPath.homeDirPath;
    await File(join(homeDirPath, 'backup.zip')).safeDelete();
    await Directory(join(homeDirPath, 'restore')).safeDelete(recursive: true);
  }

  Future<String> _createArchive(String workDir) async {
    final databaseSnapshotPath = join(workDir, backupDatabaseName);
    await database.customStatement('VACUUM INTO ?', [databaseSnapshotPath]);
    final (scriptIds, providers, mitmModules) = await (
      database.scriptsDao.query().map((item) => item.id).get(),
      database.clashProvidersDao.query().get(),
      database.mitmModulesDao.query().get(),
    ).wait;
    final configMap = ref.read(configProvider).toJson();
    configMap['currentProfileId'] = null;
    configMap['version'] = await preferences.getVersion();
    final archivePath = join(workDir, 'backup.zip');
    await backupTask((
      archivePath: archivePath,
      configMap: configMap,
      databaseSnapshotPath: databaseSnapshotPath,
      homeDirPath: await appPath.homeDirPath,
      entries: BackupEntries.of(
        profileIds: const [],
        scriptIds: scriptIds,
        providers: providers,
        mitmModules: mitmModules,
      ),
    ));
    return archivePath;
  }

  @visibleForTesting
  Future<void> applyRestore(
    MigrationData data,
    RestoreOption option, {
    String? stagingDirPath,
  }) async {
    final configMap = data.configMap;
    final config = option == RestoreOption.onlyProfiles || configMap == null
        ? null
        : Config.fromJson(configMap);
    final isOverride =
        ref.read(appSettingProvider).restoreStrategy ==
        RestoreStrategy.override;
    final sanitizedData = MigrationData(
      configMap: data.configMap,
      profiles: const [],
      scripts: data.scripts,
      rules: data.rules,
      disabledRules: data.disabledRules,
      proxyGroups: const [],
      clashProviders: data.clashProviders,
      customProxies: const [],
      proxyDialers: const [],
      mitmModules: data.mitmModules,
    );
    final keptManagedProfiles = isOverride
        ? (await database.profilesDao.query().get())
              .where((item) => item.id == youkomixManagedProfileId)
              .toList()
        : const <Profile>[];
    final previousProviders = await database.clashProvidersDao.query().get();
    final putBack = stagingDirPath == null
        ? null
        : await _copyStagedFiles(sanitizedData, stagingDirPath);
    try {
      if (isOverride) {
        final unmanaged = (await database.profilesDao.query().get())
            .where((item) => item.id != youkomixManagedProfileId)
            .toList();
        for (final item in unmanaged) {
          await database.deleteProfile(item.id);
        }
      }
      await database.restore(
        keptManagedProfiles,
        sanitizedData.scripts,
        sanitizedData.rules,
        sanitizedData.disabledRules,
        sanitizedData.proxyGroups,
        clashProviders: sanitizedData.clashProviders,
        customProxies: sanitizedData.customProxies,
        proxyDialers: sanitizedData.proxyDialers,
        mitmModules: sanitizedData.mitmModules,
        isOverride: isOverride,
      );
    } catch (_) {
      await putBack?.call();
      rethrow;
    }
    await _clearReplacedProviderCaches(previousProviders);
    await _clearOutdatedCompiledRuleSets(sanitizedData.clashProviders);
    if (config == null) {
      await _restoreMitmModules();
      if (ref.mounted) {
        unawaited(
          ref
              .read(youkomixControllerProvider.notifier)
              .refreshIfAuthenticated(),
        );
      }
      return;
    }
    final accessControlProps = config.vpnProps.accessControlProps.hasPackages
        ? config.vpnProps.accessControlProps
        : ref.read(vpnSettingProvider).accessControlProps;
    final currentProfileId = ref.read(currentProfileIdProvider);
    writeConfig(
      ref,
      config.copyWith(
        currentProfileId: currentProfileId,
        davProps: config.davProps ?? ref.read(davSettingProvider),
        vpnProps: config.vpnProps.copyWith(
          accessControlProps: accessControlProps,
        ),
      ),
    );
    await _restoreMitmModules();
    if (ref.mounted) {
      unawaited(
        ref.read(youkomixControllerProvider.notifier).refreshIfAuthenticated(),
      );
    }
  }

  Future<void> _restoreMitmModules() async {
    final action = ref.read(mitmModulesActionProvider.notifier);
    await action.clean();
    if (ref.mounted) {
      unawaited(action.autoUpdate());
    }
  }

  Future<Future<void> Function()> _copyStagedFiles(
    MigrationData data,
    String stagingDirPath,
  ) async {
    final homeDirPath = await appPath.homeDirPath;
    final replacedDirPath = join(stagingDirPath, 'replaced');
    final copied = <String, bool>{};
    Future<void> putBack() async {
      for (final MapEntry(key: entry, value: replaced) in copied.entries) {
        final target = BackupEntries.resolve(homeDirPath, entry);
        if (replaced) {
          await File(
            BackupEntries.resolve(replacedDirPath, entry),
          ).safeCopy(target);
        } else {
          await File(target).safeDelete();
        }
      }
    }

    try {
      for (final entry in BackupEntries.ofData(data)) {
        final staged = File(BackupEntries.resolve(stagingDirPath, entry));
        if (!await staged.exists()) {
          continue;
        }
        final target = File(BackupEntries.resolve(homeDirPath, entry));
        final replaced = await target.exists();
        if (replaced) {
          await target.safeCopy(BackupEntries.resolve(replacedDirPath, entry));
        }
        copied[entry] = replaced;
        await staged.safeCopy(target.path);
      }
    } catch (_) {
      await putBack();
      rethrow;
    }
    return putBack;
  }

  Future<void> _clearReplacedProviderCaches(
    List<ClashProvider> previousProviders,
  ) async {
    final kept = (await database.clashProvidersDao.fileNames().get()).toSet();
    for (final provider in previousProviders) {
      if (kept.contains(provider.fileName)) {
        continue;
      }
      await File(await provider.path).safeDelete();
      await File(await provider.compiledPath).safeDelete();
    }
  }

  Future<void> _clearOutdatedCompiledRuleSets(
    List<ClashProvider> restored,
  ) async {
    for (final provider in restored) {
      if (!provider.isRemote) {
        await File(await provider.compiledPath).safeDelete();
      }
    }
  }
}
