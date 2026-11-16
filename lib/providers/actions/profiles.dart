part of '../action.dart';

@Riverpod(keepAlive: true)
class ProfilesAction extends _$ProfilesAction {
  CoreController get _core => ref.read(coreHandlerProvider);

  @override
  void build() {}

  void updateCurrentSelectedMap(String groupName, String proxyName) {
    final currentProfile = ref.read(currentProfileProvider);
    if (currentProfile != null &&
        currentProfile.selectedMap[groupName] != proxyName) {
      final selectedMap = Map<String, String>.from(currentProfile.selectedMap)
        ..[groupName] = proxyName;
      ref
          .read(profilesProvider.notifier)
          .put(currentProfile.copyWith(selectedMap: selectedMap));
    }
  }

  Future<void> deleteProfile(int id) async {
    await ref.read(profilesProvider.notifier).del(id);
    await clearEffect(id);
    final currentProfileId = ref.read(currentProfileIdProvider);
    if (currentProfileId == id) {
      final profiles = ref.read(profilesProvider);
      if (profiles.isNotEmpty) {
        final updateId = profiles.first.id;
        ref.read(currentProfileIdProvider.notifier).value = updateId;
      } else {
        ref.read(currentProfileIdProvider.notifier).value = null;
        unawaited(ref.read(setupActionProvider.notifier).setRunning(false));
      }
    }
  }

  Future<void> purgeUnmanagedProfiles() async {
    final unmanagedIds = [
      for (final profile in ref.read(profilesProvider))
        if (profile.id != youkomixManagedProfileId) profile.id,
    ];
    for (final id in unmanagedIds) {
      await ref.read(profilesProvider.notifier).del(id);
      await clearEffect(id);
    }
    final remaining = ref.read(profilesProvider);
    if (remaining.isEmpty) {
      if (ref.read(currentProfileIdProvider) != null) {
        ref.read(currentProfileIdProvider.notifier).value = null;
      }
    } else if (ref.read(currentProfileIdProvider) != youkomixManagedProfileId) {
      ref.read(currentProfileIdProvider.notifier).value =
          youkomixManagedProfileId;
    }
  }

  Future<void> clearAllProfiles() async {
    final ids = {
      youkomixManagedProfileId,
      for (final profile in ref.read(profilesProvider)) profile.id,
    };
    for (final id in ids) {
      await ref.read(profilesProvider.notifier).del(id);
      await clearEffect(id);
    }
    ref.read(currentProfileIdProvider.notifier).value = null;
  }

  Future<Profile> saveManagedProfile({
    required Uint8List bytes,
    required String label,
    required SubscriptionInfo subscriptionInfo,
    Duration autoUpdateDuration = const Duration(hours: 6),
  }) async {
    await purgeUnmanagedProfiles();
    final existing = ref
        .read(profilesProvider)
        .getProfile(youkomixManagedProfileId);
    final base = Profile(
      id: youkomixManagedProfileId,
      type: ProfileType.file,
      url: '',
      label: label,
      autoUpdate: true,
      autoUpdateDuration: autoUpdateDuration,
      subscriptionInfo: subscriptionInfo,
      selectedMap: existing?.selectedMap ?? const {},
      unfoldSet: existing?.unfoldSet ?? const {},
      currentGroupName: existing?.currentGroupName,
      extendType: existing?.extendType ?? ExtendType.standard,
      scriptId: existing?.scriptId,
      matchTarget: existing?.matchTarget,
      overrides: existing?.overrides ?? const ProfileOverrides(),
    );
    final saved = await base.saveFile(
      bytes,
      validate: (path, key) => _core.validateProfile(path, key),
    );
    final latest = ref
        .read(profilesProvider)
        .getProfile(youkomixManagedProfileId);
    final merged = latest == null
        ? saved
        : saved.copyWith(
            selectedMap: latest.selectedMap,
            unfoldSet: latest.unfoldSet,
            currentGroupName: latest.currentGroupName,
            extendType: latest.extendType,
            scriptId: latest.scriptId,
            matchTarget: latest.matchTarget,
            overrides: latest.overrides,
          );
    ref.read(profilesProvider.notifier).put(merged);
    ref.read(currentProfileIdProvider.notifier).value =
        youkomixManagedProfileId;
    return merged;
  }

  Future<String?> validateConfigWithData(List<int> data) async {
    return _core.validateConfigWithData(data);
  }

  Future<void> autoUpdateProfiles() async {
    final existing = ref
        .read(profilesProvider)
        .getProfile(youkomixManagedProfileId);
    if (existing != null && existing.lastUpdateDate != null) {
      final elapsed = DateTime.now().difference(existing.lastUpdateDate!);
      if (elapsed < existing.autoUpdateDuration) {
        return;
      }
    }
    await ref
        .read(youkomixControllerProvider.notifier)
        .refreshIfAuthenticated();
  }

  Future<void> updateProfiles() async {
    await ref
        .read(youkomixControllerProvider.notifier)
        .syncSubscription(showFeedback: true);
  }

  Future<void> updateProfile(
    Profile profile, {
    bool showLoading = false,
  }) async {
    await ref
        .read(youkomixControllerProvider.notifier)
        .syncSubscription(showFeedback: showLoading);
  }

  void putProfile(Profile profile) {
    ref.read(profilesProvider.notifier).put(profile);
    if (ref.read(currentProfileIdProvider) != null) return;
    ref.read(currentProfileIdProvider.notifier).value = profile.id;
  }

  Future<List<Profile>> providerUsers(Profile profile) async {
    if (profile.type == ProfileType.custom) {
      return const [];
    }
    final users = await ref
        .read(clashProvidersActionProvider.notifier)
        .profilesReferencing(ProviderKind.proxy, profile.realLabel);
    return [
      for (final user in users)
        if (user.id != profile.id) user,
    ];
  }

  Future<List<Profile>> proxyUsers(Set<String> names) async {
    final (ruleTargets, dialerTargets) = await (
      database.rulesDao.targetsNaming(names),
      database.proxyDialersDao.targetsNaming(names),
    ).wait;
    final users = <Profile>[];
    for (final profile in ref.read(profilesProvider)) {
      if (profile.type != ProfileType.custom) {
        continue;
      }
      final groups = await database.proxyGroupsDao.query(profile.id).get();
      final inUse = proxyNamesInUse(
        names.difference({for (final group in groups) group.name}),
        groups: groups,
        ruleTargets: ruleTargets[profile.id] ?? const {},
        dialerTargets: dialerTargets[profile.id] ?? const {},
        overrides: profile.overrides,
      );
      if (inUse.isNotEmpty) {
        users.add(profile);
      }
    }
    return users;
  }

  Future<Set<String>> groupsInUse(int profileId, Set<int> groupIds) async {
    final groups = await database.proxyGroupsDao.query(profileId).get();
    final names = {
      for (final group in groups)
        if (groupIds.contains(group.id)) group.name,
    };
    final (ruleTargets, dialerTargets) = await (
      database.rulesDao.targetsNaming(names),
      database.proxyDialersDao.targetsNaming(names),
    ).wait;
    return proxyNamesInUse(
      names,
      groups: groups.where((group) => !groupIds.contains(group.id)),
      ruleTargets: ruleTargets[profileId] ?? const {},
      dialerTargets: dialerTargets[profileId] ?? const {},
      overrides:
          ref.read(profilesProvider).getProfile(profileId)?.overrides ??
          const ProfileOverrides(),
    );
  }

  void touchProfile(int id) {
    final profile = ref.read(profilesProvider).getProfile(id);
    if (profile == null) return;
    ref
        .read(profilesProvider.notifier)
        .put(profile.copyWith(lastUpdateDate: DateTime.now()));
  }

  Future<void> clearEffect(int profileId) async {
    final profilePath = await appPath.getProfilePath(profileId.toString());
    final profileFile = File(profilePath);
    final isExists = await profileFile.exists();
    if (isExists) {
      await profileFile.safeDelete(recursive: true);
    }
    try {
      await _core.clearEffect(profileId);
    } catch (error) {
      commonPrint.log(
        'clearEffect($profileId) failed: $error',
        logLevel: coreFailureLogLevel(error),
      );
    }
  }
}
