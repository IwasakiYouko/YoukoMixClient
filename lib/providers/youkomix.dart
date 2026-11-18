import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'action.dart';
import 'app.dart';
import 'database.dart';

const youkomixSyncUpdatingKey = 'youkomix_sync';

final youkomixGateEnabledProvider = Provider<bool>((ref) => false);

final youkomixInitialSessionProvider = Provider<YoukoMixSession?>(
  (ref) => null,
);

final youkomixCurrentAppVersionProvider = Provider<String>((ref) {
  try {
    return globalState.packageInfo.version;
  } catch (_) {
    return '';
  }
});

final youkomixApiProvider = Provider<YoukoMixApiClient>((ref) => youkomixApi);

final youkomixStorageProvider = Provider<YoukoMixSessionStorage>(
  (ref) => youkomixStorage,
);

final youkomixUrlLauncherProvider = Provider<Future<bool> Function(String url)>(
  (ref) => (url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  },
);

@immutable
class YoukoMixState {
  final bool gateEnabled;
  final String serverUrl;
  final YoukoMixMeta? meta;
  final YoukoMixSession? session;
  final YoukoMixCaptchaChallenge? captchaChallenge;
  final String? captchaServerUrl;
  final bool isLoadingCaptcha;
  final String? mfaChallengeToken;
  final String? webAuthUrl;
  final bool isBusy;
  final bool isSyncing;
  final bool isCheckingIn;
  final String? errorMessage;
  final DateTime? lastSyncedAt;
  final DateTime? lastBootstrapAt;
  final String currentAppVersion;

  const YoukoMixState({
    this.gateEnabled = false,
    this.serverUrl = '',
    this.meta,
    this.session,
    this.captchaChallenge,
    this.captchaServerUrl,
    this.isLoadingCaptcha = false,
    this.mfaChallengeToken,
    this.webAuthUrl,
    this.isBusy = false,
    this.isSyncing = false,
    this.isCheckingIn = false,
    this.errorMessage,
    this.lastSyncedAt,
    this.lastBootstrapAt,
    this.currentAppVersion = '',
  });

  bool get isAuthenticated =>
      session != null &&
      session!.accessToken.isNotEmpty &&
      session!.serverUrl.isNotEmpty;

  bool get isMfaStep =>
      mfaChallengeToken != null && mfaChallengeToken!.isNotEmpty;

  bool get shouldShowCaptcha =>
      captchaChallenge != null || (meta?.captchaEnabled ?? false);

  YoukoMixBootstrap? get bootstrap => session?.bootstrap;

  YoukoMixUser? get user => bootstrap?.user;

  YoukoMixTraffic? get traffic => bootstrap?.traffic;

  YoukoMixSubscriptionState? get subscription => bootstrap?.subscription;

  YoukoMixCommerce get commerce =>
      bootstrap?.commerce ??
      YoukoMixCommerce(enabled: meta?.commerceEnabled ?? false);

  YoukoMixFeatures get features =>
      bootstrap?.features ??
      YoukoMixFeatures(
        regMode: meta?.regMode ?? 'open',
        ticketEnabled: meta?.ticketEnabled ?? true,
        checkinEnabled: meta?.checkinEnabled ?? false,
      );

  bool get isCommerceEnabled => commerce.enabled;

  bool get canRegister => features.canRegister;

  bool get isTicketEnabled => features.ticketEnabled;

  YoukoMixSubPreference get preferredSubMode =>
      session?.preferredSubMode ?? YoukoMixSubPreference.auto;

  bool get isExclusiveActive {
    final sub = subscription;
    if (sub == null || !sub.exclusiveEnabled) {
      return false;
    }
    return switch (preferredSubMode) {
      YoukoMixSubPreference.exclusive => sub.isExclusive,
      YoukoMixSubPreference.standard => false,
      YoukoMixSubPreference.auto => sub.isExclusive,
    };
  }

  List<YoukoMixAnnouncement> get announcements =>
      bootstrap?.announcements ?? const [];

  int get maxAnnouncementId => announcements.fold<int>(
    0,
    (maxId, item) => item.id > maxId ? item.id : maxId,
  );

  bool get hasUnreadAnnouncements =>
      isAuthenticated &&
      maxAnnouncementId > (session?.lastReadAnnouncementId ?? 0);

  YoukoMixAnnouncement? get pendingPinnedAnnouncement {
    if (!isAuthenticated) {
      return null;
    }
    final readThreshold = math.max(
      session?.lastReadAnnouncementId ?? 0,
      session?.lastPromptedPinnedId ?? 0,
    );
    for (final item in announcements) {
      if (item.isPinned && item.id > readThreshold) {
        return item;
      }
    }
    return null;
  }

  YoukoMixUpgradeNotice? get upgradeNotice => bootstrap?.upgradeNotice;

  bool get isClientOutdated =>
      isYoukoMixVersionBelow(currentAppVersion, meta?.minClientVersion ?? '');

  bool get isPlanExpiredOrInactive =>
      isCommerceEnabled &&
      user != null &&
      (user!.isExpired || user!.userClass <= 0);

  bool get isQuotaExhausted =>
      traffic != null && traffic!.total > 0 && traffic!.remaining <= 0;

  bool get isQuotaOrExpiryWarning {
    if (!isCommerceEnabled || isPlanExpiredOrInactive || isQuotaExhausted) {
      return false;
    }
    final soon =
        user != null &&
        user!.userClass > 0 &&
        user!.classExpire.isNotEmpty &&
        user!.classExpireDays <= 3;
    final highUsage =
        traffic != null && traffic!.total > 0 && traffic!.usageRatio >= 0.9;
    return soon || highUsage;
  }

  String get effectiveServerUrl =>
      (session != null && session!.serverUrl.isNotEmpty)
      ? session!.serverUrl
      : serverUrl;

  String get panelBaseUrl {
    final explicitPanel = (bootstrap?.links.panelUrl ?? '').trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    if (explicitPanel.isNotEmpty) {
      return explicitPanel.endsWith('/user')
          ? explicitPanel.substring(0, explicitPanel.length - 5)
          : explicitPanel;
    }
    return effectiveServerUrl.trim().replaceAll(RegExp(r'/+$'), '');
  }

  String resolvePanelSubpath(String subpath) {
    final base = panelBaseUrl;
    if (base.isEmpty) {
      return '';
    }
    final cleanSub = subpath.startsWith('/') ? subpath : '/$subpath';
    return '$base$cleanSub';
  }

  YoukoMixState copyWith({
    bool? gateEnabled,
    String? serverUrl,
    YoukoMixMeta? meta,
    YoukoMixSession? session,
    YoukoMixCaptchaChallenge? captchaChallenge,
    String? captchaServerUrl,
    bool? isLoadingCaptcha,
    String? mfaChallengeToken,
    String? webAuthUrl,
    bool? isBusy,
    bool? isSyncing,
    bool? isCheckingIn,
    String? errorMessage,
    DateTime? lastSyncedAt,
    DateTime? lastBootstrapAt,
    String? currentAppVersion,
    bool clearSession = false,
    bool clearCaptcha = false,
    bool clearMfa = false,
    bool clearError = false,
  }) {
    return YoukoMixState(
      gateEnabled: gateEnabled ?? this.gateEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      meta: meta ?? this.meta,
      session: clearSession ? null : (session ?? this.session),
      captchaChallenge: clearCaptcha
          ? null
          : (captchaChallenge ?? this.captchaChallenge),
      captchaServerUrl: clearCaptcha
          ? null
          : (captchaServerUrl ?? this.captchaServerUrl),
      isLoadingCaptcha: isLoadingCaptcha ?? this.isLoadingCaptcha,
      mfaChallengeToken: clearMfa
          ? null
          : (mfaChallengeToken ?? this.mfaChallengeToken),
      webAuthUrl: webAuthUrl ?? this.webAuthUrl,
      isBusy: isBusy ?? this.isBusy,
      isSyncing: isSyncing ?? this.isSyncing,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastBootstrapAt: clearSession
          ? null
          : (lastBootstrapAt ?? this.lastBootstrapAt),
      currentAppVersion: currentAppVersion ?? this.currentAppVersion,
    );
  }
}

final youkomixControllerProvider =
    NotifierProvider<YoukoMixController, YoukoMixState>(YoukoMixController.new);

class YoukoMixController extends Notifier<YoukoMixState> {
  int _authEpoch = 0;
  int _captchaEpoch = 0;
  bool _isRefreshingBootstrap = false;

  YoukoMixApiClient get _api => ref.read(youkomixApiProvider);
  YoukoMixSessionStorage get _storage => ref.read(youkomixStorageProvider);

  static String? _tryNormalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return normalizeYoukoMixServerUrl(trimmed);
    } on YoukoMixApiException {
      return null;
    }
  }

  @override
  YoukoMixState build() {
    final gateEnabled = ref.watch(youkomixGateEnabledProvider);
    final initialSession = ref.watch(youkomixInitialSessionProvider);
    final currentVersion = ref.watch(youkomixCurrentAppVersionProvider);
    final initialServerUrl =
        initialSession?.serverUrl ??
        _storage.activeServerUrl ??
        defaultYoukoMixServerUrl.trim();
    return YoukoMixState(
      gateEnabled: gateEnabled,
      serverUrl: initialServerUrl,
      session: initialSession,
      currentAppVersion: currentVersion,
    );
  }

  void setServerUrl(String serverUrl) {
    final trimmed = serverUrl.trim();
    final nextNormalized = _tryNormalize(trimmed);
    final prevNormalized = _tryNormalize(state.serverUrl);
    final invalidateCaptcha =
        nextNormalized != prevNormalized ||
        (state.captchaServerUrl != null &&
            state.captchaServerUrl != nextNormalized);
    if (invalidateCaptcha) {
      ++_captchaEpoch;
    }
    state = state.copyWith(
      serverUrl: trimmed,
      clearCaptcha: invalidateCaptcha,
      isLoadingCaptcha: invalidateCaptcha ? false : state.isLoadingCaptcha,
      clearError: true,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void cancelMfa() {
    state = state.copyWith(clearMfa: true, clearError: true);
  }

  Future<void> loadMeta([String? rawServerUrl]) async {
    final target = (rawServerUrl ?? state.serverUrl).trim();
    if (target.isEmpty) {
      return;
    }
    try {
      final normalized = normalizeYoukoMixServerUrl(target);
      final metaEpoch = ++_captchaEpoch;
      final meta = await _api.fetchMeta(normalized);
      if (!ref.mounted || metaEpoch != _captchaEpoch) {
        return;
      }
      _storage.setActiveServerUrl(normalized);
      if (meta.apiEndpoints.isNotEmpty) {
        _storage.setApiEndpoints(meta.apiEndpoints, origin: normalized);
      }
      final serverMismatch =
          state.captchaServerUrl != null &&
          state.captchaServerUrl != normalized;
      state = state.copyWith(
        serverUrl: normalized,
        meta: meta,
        clearCaptcha: !meta.captchaEnabled || serverMismatch,
        webAuthUrl: meta.webAuthUrl.isNotEmpty
            ? meta.webAuthUrl
            : state.webAuthUrl,
      );
      if (meta.captchaEnabled &&
          (state.captchaChallenge == null ||
              state.captchaServerUrl != normalized)) {
        await refreshCaptcha(normalized);
      }
    } catch (_) {
      return;
    }
  }

  Future<void> refreshCaptcha([String? rawServerUrl]) async {
    final target = (rawServerUrl ?? state.serverUrl).trim();
    if (target.isEmpty) {
      return;
    }
    String normalized;
    try {
      normalized = normalizeYoukoMixServerUrl(target);
    } on YoukoMixApiException {
      return;
    }
    final reqEpoch = ++_captchaEpoch;
    state = state.copyWith(isLoadingCaptcha: true);
    try {
      final challenge = await _api.fetchCaptcha(normalized);
      if (!ref.mounted || reqEpoch != _captchaEpoch) {
        return;
      }
      final currentNormalized = _tryNormalize(state.serverUrl) ?? normalized;
      if (currentNormalized != normalized) {
        state = state.copyWith(isLoadingCaptcha: false);
        return;
      }
      state = state.copyWith(
        captchaChallenge: challenge,
        captchaServerUrl: normalized,
        isLoadingCaptcha: false,
      );
    } catch (_) {
      if (ref.mounted && reqEpoch == _captchaEpoch) {
        state = state.copyWith(isLoadingCaptcha: false);
      }
    }
  }

  Future<bool> login({
    required String serverUrl,
    required String email,
    required String password,
    String? captchaCode,
  }) async {
    if (state.isBusy) {
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true, clearMfa: true);
    String normalized = '';
    String activeCaptchaId = '';
    try {
      normalized = normalizeYoukoMixServerUrl(serverUrl);
      _storage.setActiveServerUrl(normalized);
      final validBoundCaptcha =
          state.captchaServerUrl == normalized ||
          state.captchaServerUrl == null;
      activeCaptchaId = validBoundCaptcha
          ? (state.captchaChallenge?.captchaId.trim() ?? '')
          : '';
      final trimmedCaptchaCode = captchaCode?.trim() ?? '';
      final outcome = (activeCaptchaId.isEmpty && trimmedCaptchaCode.isEmpty)
          ? await _api.login(
              serverUrl: normalized,
              email: email,
              password: password,
            )
          : await _api.login(
              serverUrl: normalized,
              email: email,
              password: password,
              captchaId: activeCaptchaId.isNotEmpty ? activeCaptchaId : null,
              captchaCode: trimmedCaptchaCode.isNotEmpty
                  ? trimmedCaptchaCode
                  : null,
            );
      if (!ref.mounted) {
        return false;
      }
      switch (outcome) {
        case YoukoMixLoginAuthenticated(:final session):
          await _completeAuthenticatedSession(session);
          return true;
        case YoukoMixLoginMfaRequired(:final challengeToken, :final webAuthUrl):
          state = state.copyWith(
            isBusy: false,
            serverUrl: normalized,
            clearCaptcha: true,
            mfaChallengeToken: challengeToken,
            webAuthUrl: webAuthUrl,
          );
          return false;
        case YoukoMixLoginCaptchaRequired(
          :final challenge,
          :final webAuthUrl,
          :final message,
        ):
          state = state.copyWith(
            isBusy: false,
            serverUrl: normalized,
            captchaChallenge: challenge,
            captchaServerUrl: challenge != null ? normalized : null,
            clearCaptcha: challenge == null,
            webAuthUrl: webAuthUrl,
            errorMessage: message,
          );
          if (challenge == null && webAuthUrl.isNotEmpty) {
            unawaited(openExternalUrl(webAuthUrl));
          }
          return false;
      }
    } on YoukoMixApiException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isBusy: false, errorMessage: error.message);
        if (activeCaptchaId.isNotEmpty && normalized.isNotEmpty) {
          unawaited(refreshCaptcha(normalized));
        }
      }
      return false;
    } on MessageException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isBusy: false, errorMessage: error.message);
      }
      return false;
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: compactError(error),
        );
      }
      return false;
    }
  }

  Future<bool> verifyMfa(String code) async {
    final challenge = state.mfaChallengeToken;
    if (state.isBusy || challenge == null || challenge.isEmpty) {
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final session = await _api.verifyMfa(
        serverUrl: state.serverUrl,
        challengeToken: challenge,
        code: code,
      );
      if (!ref.mounted) {
        return false;
      }
      await _completeAuthenticatedSession(session);
      return true;
    } on YoukoMixApiException catch (error) {
      if (ref.mounted) {
        final resetMfa =
            error.errorCode == 'mfa_expired' || error.errorCode == 'mfa_locked';
        state = state.copyWith(
          isBusy: false,
          clearMfa: resetMfa,
          errorMessage: error.message,
        );
      }
      return false;
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: compactError(error),
        );
      }
      return false;
    }
  }

  Future<bool> exchangeCode({required String code, String? serverUrl}) async {
    if (state.isBusy) {
      return false;
    }
    final targetServer = (serverUrl != null && serverUrl.trim().isNotEmpty)
        ? serverUrl.trim()
        : state.serverUrl;
    state = state.copyWith(isBusy: true, clearError: true, clearMfa: true);
    try {
      final normalized = normalizeYoukoMixServerUrl(targetServer);
      _storage.setActiveServerUrl(normalized);
      final session = await _api.exchangeCode(
        serverUrl: normalized,
        code: code,
      );
      if (!ref.mounted) {
        return false;
      }
      await _completeAuthenticatedSession(session);
      return true;
    } on YoukoMixApiException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isBusy: false, errorMessage: error.message);
      }
      return false;
    } catch (error) {
      if (ref.mounted) {
        state = state.copyWith(
          isBusy: false,
          errorMessage: compactError(error),
        );
      }
      return false;
    }
  }

  Future<void> openWebAuth([String? rawServerUrl]) async {
    final candidate = (rawServerUrl ?? state.serverUrl).trim();
    try {
      final base = normalizeYoukoMixServerUrl(candidate);
      _storage.setActiveServerUrl(base);
      final uri = Uri.parse('$base/user/client-auth').replace(
        queryParameters: {
          'platform': YoukoMixApiClient.currentPlatformName(),
          'device': YoukoMixApiClient.currentDeviceName(),
        },
      );
      final targetUrl = uri.toString();
      state = state.copyWith(
        serverUrl: base,
        webAuthUrl: targetUrl,
        clearError: true,
      );
      await openExternalUrl(targetUrl);
    } on YoukoMixApiException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    }
  }

  Future<bool> openExternalUrl(String url) {
    return ref.read(youkomixUrlLauncherProvider)(url);
  }

  Future<bool> openPanelSubpath(String subpath) {
    final target = state.resolvePanelSubpath(subpath);
    if (target.isEmpty) {
      return Future.value(false);
    }
    return openExternalUrl(target);
  }

  String buildDiagnosticSummary({
    bool isTunEnabled = false,
    bool isSystemProxyEnabled = false,
  }) {
    final version = state.currentAppVersion.isNotEmpty
        ? 'v${state.currentAppVersion}'
        : 'unknown';
    final platform =
        '${Platform.operatingSystem} (${Platform.operatingSystemVersion.split(' ').first})';
    final takeover = [
      if (isTunEnabled) 'TUN',
      if (isSystemProxyEnabled) 'System',
    ];
    final modeText = takeover.isEmpty ? 'Idle' : takeover.join('+');
    final channelText = state.isExclusiveActive ? 'Dedicated' : 'Standard';
    final user = state.user;
    final devicesText = user == null
        ? '-'
        : (user.nodeIpLimit > 0
              ? '${user.onlineIpCount}/${user.nodeIpLimit}'
              : '${user.onlineIpCount}/unlimited');
    final syncedText =
        state.lastSyncedAt?.toIso8601String().split('.').first ?? '-';
    return [
      '$appCodeName $version',
      'OS: $platform',
      'Mode: $modeText',
      'Channel: $channelText',
      'Devices: $devicesText',
      'Synced: $syncedText',
    ].join(' | ');
  }

  static int _effectiveExpireEpoch(YoukoMixBootstrap bootstrap) {
    if (!bootstrap.commerce.enabled || bootstrap.user.userClass <= 0) {
      return 0;
    }
    return (bootstrap.user.classExpireDate?.millisecondsSinceEpoch ?? 0) ~/
        1000;
  }

  Future<bool> checkin() async {
    final currentSession = state.session;
    if (currentSession == null ||
        !state.isAuthenticated ||
        state.isCheckingIn ||
        state.isBusy) {
      return false;
    }
    final features = state.features;
    if (!features.checkinEnabled) {
      return false;
    }
    if (features.checkinCaptchaEnabled) {
      await openPanelSubpath('/user');
      return false;
    }
    final reqEpoch = _authEpoch;
    state = state.copyWith(isCheckingIn: true, clearError: true);
    try {
      final result = await _api.checkin(
        serverUrl: currentSession.serverUrl,
        accessToken: currentSession.accessToken,
      );
      if (!ref.mounted || reqEpoch != _authEpoch) {
        return false;
      }
      final prevMode =
          currentSession.bootstrap?.subscription.activeMode ??
          result.bootstrap.subscription.activeMode;
      final mergedBootstrap = result.bootstrap.copyWith(
        subscription: result.bootstrap.subscription.copyWith(
          activeMode: prevMode,
        ),
      );
      final existingProfile = ref
          .read(profilesProvider)
          .getProfile(youkomixManagedProfileId);
      if (existingProfile != null && mergedBootstrap.traffic.total > 0) {
        ref
            .read(profilesProvider.notifier)
            .put(
              existingProfile.copyWith(
                subscriptionInfo: SubscriptionInfo(
                  upload: mergedBootstrap.traffic.upload,
                  download: mergedBootstrap.traffic.download,
                  total: mergedBootstrap.traffic.total,
                  expire: _effectiveExpireEpoch(mergedBootstrap),
                ),
              ),
            );
      }
      final latestSession = state.session ?? currentSession;
      final updatedSession = latestSession.copyWith(
        apiEndpoints: mergedBootstrap.apiEndpoints.isNotEmpty
            ? mergedBootstrap.apiEndpoints
            : latestSession.apiEndpoints,
        bootstrap: mergedBootstrap,
      );
      await _storage.saveSession(updatedSession);
      if (!ref.mounted || reqEpoch != _authEpoch) {
        return false;
      }
      state = state.copyWith(
        session: updatedSession,
        isCheckingIn: false,
        lastBootstrapAt: DateTime.now(),
      );
      final bannerText = result.message.isNotEmpty
          ? result.message
          : '+${result.trafficMb} MB';
      dialogs.showBanner(bannerText, level: BannerLevel.success);
      return true;
    } on YoukoMixApiException catch (error) {
      if (!ref.mounted || reqEpoch != _authEpoch) {
        return false;
      }
      if (error.isSessionInvalid) {
        await _forceSignOut(currentAppLocalizations.youkomixSessionExpired);
        return false;
      }
      state = state.copyWith(isCheckingIn: false);
      if (error.errorCode == 'checkin_captcha_required') {
        final webUrl = error.data['web_url']?.toString() ?? '';
        if (webUrl.isNotEmpty) {
          unawaited(openExternalUrl(webUrl));
        } else {
          unawaited(openPanelSubpath('/user'));
        }
      } else if (error.errorCode == 'already_checked_in') {
        final curBoot = state.session?.bootstrap;
        if (curBoot != null) {
          final patchedSession = state.session!.copyWith(
            bootstrap: curBoot.copyWith(
              features: curBoot.features.copyWith(ableToCheckin: false),
            ),
          );
          state = state.copyWith(session: patchedSession);
          unawaited(_storage.saveSession(patchedSession));
        }
      }
      dialogs.showBanner(error.message, level: BannerLevel.error);
      return false;
    } catch (error) {
      if (ref.mounted && reqEpoch == _authEpoch) {
        final msg = compactError(error);
        state = state.copyWith(isCheckingIn: false);
        dialogs.showBanner(msg, level: BannerLevel.error);
      }
      return false;
    }
  }

  Future<void> markAnnouncementsRead({int? upToId}) async {
    final currentSession = state.session;
    if (currentSession == null) {
      return;
    }
    final targetId = upToId ?? state.maxAnnouncementId;
    if (targetId <= currentSession.lastReadAnnouncementId &&
        targetId <= currentSession.lastPromptedPinnedId) {
      return;
    }
    final updated = currentSession.copyWith(
      lastReadAnnouncementId: math.max(
        currentSession.lastReadAnnouncementId,
        targetId,
      ),
      lastPromptedPinnedId: math.max(
        currentSession.lastPromptedPinnedId,
        targetId,
      ),
    );
    state = state.copyWith(session: updated);
    await _storage.saveSession(updated);
  }

  Future<void> acknowledgePinnedAnnouncement(int announcementId) async {
    await markAnnouncementsRead(upToId: announcementId);
  }

  Future<bool> switchSubscriptionMode(YoukoMixSubPreference targetMode) async {
    final currentSession = state.session;
    if (currentSession == null || state.isSyncing || state.isBusy) {
      return false;
    }
    final wantExclusive = targetMode == YoukoMixSubPreference.exclusive;
    if (wantExclusive && !(state.subscription?.exclusiveEnabled ?? false)) {
      return false;
    }
    if (state.isExclusiveActive == wantExclusive &&
        currentSession.preferredSubMode == targetMode) {
      return true;
    }
    return syncSubscription(showFeedback: true, overridePreference: targetMode);
  }

  Future<bool> syncSubscription({
    bool showFeedback = false,
    YoukoMixBootstrap? reuseBootstrap,
    YoukoMixSubPreference? overridePreference,
  }) async {
    final currentSession = state.session;
    if (currentSession == null || state.isSyncing) {
      return false;
    }
    final syncEpoch = _authEpoch;
    final operation = ref
        .read(updatingKeysProvider.notifier)
        .start(youkomixSyncUpdatingKey);
    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      final rawBootstrap =
          reuseBootstrap ??
          await _api.fetchBootstrap(
            serverUrl: currentSession.serverUrl,
            accessToken: currentSession.accessToken,
          );
      if (rawBootstrap.apiEndpoints.isNotEmpty) {
        _storage.setApiEndpoints(
          rawBootstrap.apiEndpoints,
          origin: currentSession.serverUrl,
        );
      }
      final basePreference =
          overridePreference ?? currentSession.preferredSubMode;
      final effectivePreference =
          (!rawBootstrap.subscription.exclusiveEnabled &&
              basePreference == YoukoMixSubPreference.exclusive)
          ? YoukoMixSubPreference.auto
          : basePreference;
      final requestMode = effectivePreference.apiValue;
      final payload = requestMode == 'auto'
          ? await _api.downloadSubscription(
              serverUrl: currentSession.serverUrl,
              accessToken: currentSession.accessToken,
              userAgent: _resolveUserAgent(),
            )
          : await _api.downloadSubscription(
              serverUrl: currentSession.serverUrl,
              accessToken: currentSession.accessToken,
              mode: requestMode,
              userAgent: _resolveUserAgent(),
            );
      if (!ref.mounted || syncEpoch != _authEpoch) {
        return false;
      }
      final resolvedMode = payload.mode == 'exclusive'
          ? 'exclusive'
          : 'standard';
      final bootstrap = rawBootstrap.copyWith(
        subscription: rawBootstrap.subscription.copyWith(
          activeMode: resolvedMode,
        ),
      );
      final expireEpoch = _effectiveExpireEpoch(bootstrap);
      final parsedHeaderInfo = SubscriptionInfo.formHString(
        payload.userInfoHeader,
      );
      final subInfo = bootstrap.traffic.total > 0 || expireEpoch > 0
          ? SubscriptionInfo(
              upload: bootstrap.traffic.upload,
              download: bootstrap.traffic.download,
              total: bootstrap.traffic.total,
              expire: expireEpoch,
            )
          : SubscriptionInfo(
              upload: parsedHeaderInfo.upload,
              download: parsedHeaderInfo.download,
              total: parsedHeaderInfo.total,
              expire:
                  (!bootstrap.commerce.enabled || bootstrap.user.userClass <= 0)
                  ? 0
                  : parsedHeaderInfo.expire,
            );
      final label =
          resolvedMode == 'exclusive' &&
              bootstrap.subscription.exclusiveTitle.trim().isNotEmpty
          ? bootstrap.subscription.exclusiveTitle.trim()
          : (payload.title.trim().isNotEmpty ? payload.title.trim() : appName);

      final previousMode = currentSession.bootstrap?.subscription.activeMode;
      final modeChanged = previousMode != null && previousMode != resolvedMode;

      await ref
          .read(profilesActionProvider.notifier)
          .saveManagedProfile(
            bytes: payload.bytes,
            label: label,
            subscriptionInfo: subInfo,
            autoUpdateDuration: Duration(hours: payload.updateIntervalHours),
            resetSelection: modeChanged,
          );
      if (!ref.mounted || syncEpoch != _authEpoch) {
        await ref.read(profilesActionProvider.notifier).clearAllProfiles();
        return false;
      }

      final updatedSession = currentSession.copyWith(
        preferredSubMode: effectivePreference,
        apiEndpoints: bootstrap.apiEndpoints.isNotEmpty
            ? bootstrap.apiEndpoints
            : currentSession.apiEndpoints,
        bootstrap: bootstrap,
      );
      await _storage.saveSession(updatedSession);
      if (!ref.mounted || syncEpoch != _authEpoch) {
        await _storage.clearSession();
        return false;
      }
      ref
          .read(setupActionProvider.notifier)
          .applyProfileDebounce(silence: !showFeedback, force: true);
      final now = DateTime.now();
      state = state.copyWith(
        session: updatedSession,
        isSyncing: false,
        lastSyncedAt: now,
        lastBootstrapAt: now,
        clearError: true,
      );
      if (showFeedback) {
        dialogs.showBanner(
          currentAppLocalizations.youkomixSyncSuccess,
          level: BannerLevel.info,
        );
      }
      return true;
    } on YoukoMixApiException catch (error) {
      if (!ref.mounted || syncEpoch != _authEpoch) {
        return false;
      }
      if (error.isSessionInvalid) {
        await _forceSignOut(currentAppLocalizations.youkomixSessionExpired);
        return false;
      }
      state = state.copyWith(isSyncing: false, errorMessage: error.message);
      if (showFeedback) {
        dialogs.showBanner(error.message, level: BannerLevel.error);
      }
      return false;
    } on MessageException catch (error) {
      if (ref.mounted && syncEpoch == _authEpoch) {
        state = state.copyWith(isSyncing: false, errorMessage: error.message);
        if (showFeedback) {
          dialogs.showBanner(error.message, level: BannerLevel.error);
        }
      }
      return false;
    } catch (error) {
      final msg = compactError(error);
      if (ref.mounted && syncEpoch == _authEpoch) {
        state = state.copyWith(isSyncing: false, errorMessage: msg);
        if (showFeedback) {
          dialogs.showBanner(msg, level: BannerLevel.error);
        }
      }
      return false;
    } finally {
      if (ref.mounted) {
        ref
            .read(updatingKeysProvider.notifier)
            .stop(youkomixSyncUpdatingKey, operation);
      }
    }
  }

  Future<bool> refreshBootstrapIfNeeded({
    Duration minInterval = const Duration(minutes: 15),
    bool force = false,
  }) async {
    final currentSession = state.session;
    if (currentSession == null ||
        !state.isAuthenticated ||
        state.isSyncing ||
        state.isBusy ||
        _isRefreshingBootstrap) {
      return false;
    }
    final lastAt = state.lastBootstrapAt;
    if (!force &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < minInterval) {
      return false;
    }
    final reqEpoch = _authEpoch;
    _isRefreshingBootstrap = true;
    try {
      if (state.meta == null) {
        unawaited(loadMeta(currentSession.serverUrl));
      }
      final rawBootstrap = await _api.fetchBootstrap(
        serverUrl: currentSession.serverUrl,
        accessToken: currentSession.accessToken,
      );
      if (!ref.mounted || reqEpoch != _authEpoch) {
        return false;
      }
      if (rawBootstrap.apiEndpoints.isNotEmpty) {
        _storage.setApiEndpoints(
          rawBootstrap.apiEndpoints,
          origin: currentSession.serverUrl,
        );
      }
      final prevActiveMode =
          currentSession.bootstrap?.subscription.activeMode ??
          rawBootstrap.subscription.activeMode;
      if (prevActiveMode == 'exclusive' &&
          !rawBootstrap.subscription.exclusiveEnabled) {
        _isRefreshingBootstrap = false;
        return await syncSubscription(reuseBootstrap: rawBootstrap);
      }
      final mergedBootstrap = rawBootstrap.copyWith(
        subscription: rawBootstrap.subscription.copyWith(
          activeMode: prevActiveMode,
        ),
      );
      final existingProfile = ref
          .read(profilesProvider)
          .getProfile(youkomixManagedProfileId);
      if (existingProfile != null) {
        final expireEpoch = _effectiveExpireEpoch(mergedBootstrap);
        if (mergedBootstrap.traffic.total > 0 || expireEpoch > 0) {
          ref
              .read(profilesProvider.notifier)
              .put(
                existingProfile.copyWith(
                  subscriptionInfo: SubscriptionInfo(
                    upload: mergedBootstrap.traffic.upload,
                    download: mergedBootstrap.traffic.download,
                    total: mergedBootstrap.traffic.total,
                    expire: expireEpoch,
                  ),
                ),
              );
        }
      }
      final latestSession = state.session ?? currentSession;
      final updatedSession = latestSession.copyWith(
        apiEndpoints: mergedBootstrap.apiEndpoints.isNotEmpty
            ? mergedBootstrap.apiEndpoints
            : latestSession.apiEndpoints,
        bootstrap: mergedBootstrap,
      );
      await _storage.saveSession(updatedSession);
      if (!ref.mounted || reqEpoch != _authEpoch) {
        return false;
      }
      state = state.copyWith(
        session: updatedSession,
        lastBootstrapAt: DateTime.now(),
      );
      return true;
    } on YoukoMixApiException catch (error) {
      if (ref.mounted && reqEpoch == _authEpoch && error.isSessionInvalid) {
        await _forceSignOut(currentAppLocalizations.youkomixSessionExpired);
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshingBootstrap = false;
    }
  }

  Future<void> refreshIfAuthenticated() async {
    if (!state.isAuthenticated) {
      return;
    }
    await syncSubscription();
  }

  Future<bool> handleDeepLink(YoukoMixDeepLink link) async {
    return switch (link) {
      YoukoMixAuthDeepLink(:final code, :final serverUrl) => exchangeCode(
        code: code,
        serverUrl: serverUrl,
      ),
      YoukoMixSyncDeepLink(:final mode) =>
        !state.isAuthenticated
            ? Future.value(false)
            : syncSubscription(showFeedback: true, overridePreference: mode),
    };
  }

  Future<bool> handleRawDeepLink(String raw) {
    final parsed = parseYoukoMixDeepLink(raw);
    if (parsed == null) {
      return Future.value(false);
    }
    return handleDeepLink(parsed);
  }

  Future<void> logout() async {
    ++_authEpoch;
    ++_captchaEpoch;
    final currentSession = state.session;
    state = state.copyWith(isBusy: true, isSyncing: false, clearError: true);
    if (currentSession != null) {
      try {
        await _api.logout(
          serverUrl: currentSession.serverUrl,
          accessToken: currentSession.accessToken,
        );
      } catch (_) {}
    }
    await _purgeLocalSessionState();
    if (!ref.mounted) {
      return;
    }
    state = YoukoMixState(
      gateEnabled: state.gateEnabled,
      serverUrl: state.serverUrl,
      meta: state.meta,
      currentAppVersion: state.currentAppVersion,
    );
  }

  Future<void> _completeAuthenticatedSession(YoukoMixSession session) async {
    ++_authEpoch;
    ++_captchaEpoch;
    await _storage.saveSession(session);
    await ref.read(profilesActionProvider.notifier).purgeUnmanagedProfiles();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      serverUrl: session.serverUrl,
      session: session,
      isBusy: false,
      isSyncing: false,
      clearCaptcha: true,
      clearMfa: true,
      clearError: true,
    );
    await syncSubscription(reuseBootstrap: session.bootstrap);
  }

  Future<void> _forceSignOut(String message) async {
    ++_authEpoch;
    ++_captchaEpoch;
    await _purgeLocalSessionState();
    if (!ref.mounted) {
      return;
    }
    state = YoukoMixState(
      gateEnabled: state.gateEnabled,
      serverUrl: state.serverUrl,
      meta: state.meta,
      errorMessage: message,
      currentAppVersion: state.currentAppVersion,
    );
    dialogs.showBanner(message, level: BannerLevel.error);
  }

  Future<void> _purgeLocalSessionState() async {
    try {
      await ref.read(setupActionProvider.notifier).setRunning(false);
    } catch (_) {}
    await ref.read(profilesActionProvider.notifier).clearAllProfiles();
    await _storage.clearSession();
  }

  String _resolveUserAgent() {
    try {
      return globalState.ua;
    } catch (_) {
      return '$appCodeName/1.1';
    }
  }
}
