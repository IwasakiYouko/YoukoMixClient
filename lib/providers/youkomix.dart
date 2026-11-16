import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'action.dart';
import 'app.dart';

const youkomixSyncUpdatingKey = 'youkomix_sync';

final youkomixGateEnabledProvider = Provider<bool>((ref) => false);

final youkomixInitialSessionProvider = Provider<YoukoMixSession?>(
  (ref) => null,
);

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
  final bool isLoadingCaptcha;
  final String? mfaChallengeToken;
  final String? webAuthUrl;
  final bool isBusy;
  final bool isSyncing;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  const YoukoMixState({
    this.gateEnabled = false,
    this.serverUrl = '',
    this.meta,
    this.session,
    this.captchaChallenge,
    this.isLoadingCaptcha = false,
    this.mfaChallengeToken,
    this.webAuthUrl,
    this.isBusy = false,
    this.isSyncing = false,
    this.errorMessage,
    this.lastSyncedAt,
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

  String get effectiveServerUrl =>
      (session != null && session!.serverUrl.isNotEmpty)
      ? session!.serverUrl
      : serverUrl;

  YoukoMixState copyWith({
    bool? gateEnabled,
    String? serverUrl,
    YoukoMixMeta? meta,
    YoukoMixSession? session,
    YoukoMixCaptchaChallenge? captchaChallenge,
    bool? isLoadingCaptcha,
    String? mfaChallengeToken,
    String? webAuthUrl,
    bool? isBusy,
    bool? isSyncing,
    String? errorMessage,
    DateTime? lastSyncedAt,
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
      isLoadingCaptcha: isLoadingCaptcha ?? this.isLoadingCaptcha,
      mfaChallengeToken: clearMfa
          ? null
          : (mfaChallengeToken ?? this.mfaChallengeToken),
      webAuthUrl: webAuthUrl ?? this.webAuthUrl,
      isBusy: isBusy ?? this.isBusy,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

final youkomixControllerProvider =
    NotifierProvider<YoukoMixController, YoukoMixState>(YoukoMixController.new);

class YoukoMixController extends Notifier<YoukoMixState> {
  int _authEpoch = 0;

  YoukoMixApiClient get _api => ref.read(youkomixApiProvider);
  YoukoMixSessionStorage get _storage => ref.read(youkomixStorageProvider);

  @override
  YoukoMixState build() {
    final gateEnabled = ref.watch(youkomixGateEnabledProvider);
    final initialSession = ref.watch(youkomixInitialSessionProvider);
    final initialServerUrl =
        initialSession?.serverUrl ??
        _storage.activeServerUrl ??
        defaultYoukoMixServerUrl.trim();
    return YoukoMixState(
      gateEnabled: gateEnabled,
      serverUrl: initialServerUrl,
      session: initialSession,
    );
  }

  void setServerUrl(String serverUrl) {
    state = state.copyWith(serverUrl: serverUrl.trim(), clearError: true);
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
      final meta = await _api.fetchMeta(normalized);
      if (!ref.mounted) {
        return;
      }
      _storage.setActiveServerUrl(normalized);
      if (meta.apiEndpoints.isNotEmpty) {
        _storage.setApiEndpoints(meta.apiEndpoints);
      }
      state = state.copyWith(
        serverUrl: normalized,
        meta: meta,
        clearCaptcha: !meta.captchaEnabled,
        webAuthUrl: meta.webAuthUrl.isNotEmpty
            ? meta.webAuthUrl
            : state.webAuthUrl,
      );
      if (meta.captchaEnabled && state.captchaChallenge == null) {
        await refreshCaptcha(normalized);
      }
    } catch (_) {
      return;
    }
  }

  Future<void> refreshCaptcha([String? rawServerUrl]) async {
    final target = (rawServerUrl ?? state.serverUrl).trim();
    if (target.isEmpty || state.isLoadingCaptcha) {
      return;
    }
    String normalized;
    try {
      normalized = normalizeYoukoMixServerUrl(target);
    } on YoukoMixApiException {
      return;
    }
    state = state.copyWith(isLoadingCaptcha: true);
    try {
      final challenge = await _api.fetchCaptcha(normalized);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        captchaChallenge: challenge,
        isLoadingCaptcha: false,
      );
    } catch (_) {
      if (ref.mounted) {
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
    final activeCaptchaId = state.captchaChallenge?.captchaId.trim() ?? '';
    final trimmedCaptchaCode = captchaCode?.trim() ?? '';
    state = state.copyWith(isBusy: true, clearError: true, clearMfa: true);
    String normalized = '';
    try {
      normalized = normalizeYoukoMixServerUrl(serverUrl);
      _storage.setActiveServerUrl(normalized);
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
        _storage.setApiEndpoints(rawBootstrap.apiEndpoints);
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
      final expireEpoch =
          (bootstrap.user.classExpireDate?.millisecondsSinceEpoch ?? 0) ~/ 1000;
      final subInfo = bootstrap.traffic.total > 0 || expireEpoch > 0
          ? SubscriptionInfo(
              upload: bootstrap.traffic.upload,
              download: bootstrap.traffic.download,
              total: bootstrap.traffic.total,
              expire: expireEpoch,
            )
          : SubscriptionInfo.formHString(payload.userInfoHeader);
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
      state = state.copyWith(
        session: updatedSession,
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
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
    );
  }

  Future<void> _completeAuthenticatedSession(YoukoMixSession session) async {
    ++_authEpoch;
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
    await _purgeLocalSessionState();
    if (!ref.mounted) {
      return;
    }
    state = YoukoMixState(
      gateEnabled: state.gateEnabled,
      serverUrl: state.serverUrl,
      meta: state.meta,
      errorMessage: message,
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
