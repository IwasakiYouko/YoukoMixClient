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

  YoukoMixBootstrap? get bootstrap => session?.bootstrap;

  YoukoMixUser? get user => bootstrap?.user;

  YoukoMixTraffic? get traffic => bootstrap?.traffic;

  YoukoMixSubscriptionState? get subscription => bootstrap?.subscription;

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
    String? mfaChallengeToken,
    String? webAuthUrl,
    bool? isBusy,
    bool? isSyncing,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool clearSession = false,
    bool clearMfa = false,
    bool clearError = false,
  }) {
    return YoukoMixState(
      gateEnabled: gateEnabled ?? this.gateEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      meta: meta ?? this.meta,
      session: clearSession ? null : (session ?? this.session),
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
      state = state.copyWith(
        serverUrl: normalized,
        meta: meta,
        webAuthUrl: meta.webAuthUrl.isNotEmpty
            ? meta.webAuthUrl
            : state.webAuthUrl,
      );
    } on YoukoMixApiException {
      return;
    }
  }

  Future<bool> login({
    required String serverUrl,
    required String email,
    required String password,
  }) async {
    if (state.isBusy) {
      return false;
    }
    state = state.copyWith(isBusy: true, clearError: true, clearMfa: true);
    try {
      final normalized = normalizeYoukoMixServerUrl(serverUrl);
      _storage.setActiveServerUrl(normalized);
      final outcome = await _api.login(
        serverUrl: normalized,
        email: email,
        password: password,
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
            mfaChallengeToken: challengeToken,
            webAuthUrl: webAuthUrl,
          );
          return false;
        case YoukoMixLoginCaptchaRequired(:final webAuthUrl, :final message):
          state = state.copyWith(
            isBusy: false,
            serverUrl: normalized,
            webAuthUrl: webAuthUrl,
            errorMessage: message,
          );
          unawaited(openExternalUrl(webAuthUrl));
          return false;
      }
    } on YoukoMixApiException catch (error) {
      if (ref.mounted) {
        state = state.copyWith(isBusy: false, errorMessage: error.message);
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

  Future<bool> syncSubscription({
    bool showFeedback = false,
    YoukoMixBootstrap? reuseBootstrap,
  }) async {
    final currentSession = state.session;
    if (currentSession == null || state.isSyncing) {
      return false;
    }
    final operation = ref
        .read(updatingKeysProvider.notifier)
        .start(youkomixSyncUpdatingKey);
    state = state.copyWith(isSyncing: true, clearError: true);
    try {
      final bootstrap =
          reuseBootstrap ??
          await _api.fetchBootstrap(
            serverUrl: currentSession.serverUrl,
            accessToken: currentSession.accessToken,
          );
      final payload = await _api.downloadSubscription(
        serverUrl: currentSession.serverUrl,
        accessToken: currentSession.accessToken,
        userAgent: _resolveUserAgent(),
      );
      if (!ref.mounted) {
        return false;
      }
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
          bootstrap.subscription.isExclusive &&
              bootstrap.subscription.exclusiveTitle.trim().isNotEmpty
          ? bootstrap.subscription.exclusiveTitle.trim()
          : (payload.title.trim().isNotEmpty ? payload.title.trim() : appName);

      await ref
          .read(profilesActionProvider.notifier)
          .saveManagedProfile(
            bytes: payload.bytes,
            label: label,
            subscriptionInfo: subInfo,
            autoUpdateDuration: Duration(hours: payload.updateIntervalHours),
          );

      final updatedSession = currentSession.copyWith(bootstrap: bootstrap);
      await _storage.saveSession(updatedSession);
      if (!ref.mounted) {
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
      if (!ref.mounted) {
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
      if (ref.mounted) {
        state = state.copyWith(isSyncing: false, errorMessage: error.message);
        if (showFeedback) {
          dialogs.showBanner(error.message, level: BannerLevel.error);
        }
      }
      return false;
    } catch (error) {
      final msg = compactError(error);
      if (ref.mounted) {
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
      YoukoMixSyncDeepLink() =>
        state.isAuthenticated
            ? syncSubscription(showFeedback: true)
            : Future.value(false),
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
    final currentSession = state.session;
    state = state.copyWith(isBusy: true, clearError: true);
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
    await _storage.saveSession(session);
    await ref.read(profilesActionProvider.notifier).purgeUnmanagedProfiles();
    if (!ref.mounted) {
      return;
    }
    state = state.copyWith(
      serverUrl: session.serverUrl,
      session: session,
      isBusy: false,
      clearMfa: true,
      clearError: true,
    );
    await syncSubscription(reuseBootstrap: session.bootstrap);
  }

  Future<void> _forceSignOut(String message) async {
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
      return '$appCodeName/1.0';
    }
  }
}
