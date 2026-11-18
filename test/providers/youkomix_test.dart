import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/database/database.dart';
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
import '../helpers/youkomix_e2ee_server.dart';

class _MockApiClient extends Mock implements YoukoMixApiClient {}

class _MockCoreHandler extends Mock implements CoreHandlerInterface {}

class _IdleSetupAction extends SetupAction {
  @override
  void applyProfileDebounce({bool silence = false, bool force = false}) {}

  @override
  Future<bool> setRunning(bool isRun, {bool initialize = false}) async => false;
}

YoukoMixBootstrap _bootstrap() {
  return const YoukoMixBootstrap(
    user: YoukoMixUser(
      id: 1,
      email: 'reimu@example.com',
      userName: '博丽灵梦',
      userClass: 2,
      classExpire: '2027-06-01 00:00:00',
      classExpireDays: 180,
      money: '25.00',
    ),
    traffic: YoukoMixTraffic(
      upload: 1024,
      download: 2048,
      used: 3072,
      total: 10240,
      remaining: 7168,
    ),
    subscription: YoukoMixSubscriptionState(
      exclusiveEnabled: true,
      exclusiveTitle: '人间之里 · 专属订阅',
      activeMode: 'exclusive',
      updateIntervalHours: 6,
    ),
  );
}

YoukoMixSubscriptionPayload _payload() {
  return YoukoMixSubscriptionPayload(
    bytes: Uint8List.fromList(
      utf8.encode('proxies:\n  - {name: HK-01, type: ss}\n'),
    ),
    mode: 'exclusive',
    title: '人间之里',
    updateIntervalHours: 6,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory home;
  late Database testDb;
  late _MockApiClient api;
  late _MockCoreHandler core;
  late YoukoMixSessionStorage storage;
  late List<String> launchedUrls;

  setUpAll(() async {
    await AppLocalizations.load(const Locale('en'));
    home = Directory.systemTemp.createTempSync('youkomix-provider-test-');
    await useAppPaths(home);
  });

  tearDownAll(() {
    if (home.existsSync()) home.deleteSync(recursive: true);
  });

  setUp(() {
    testDb = Database(NativeDatabase.memory());
    database = testDb;
    api = _MockApiClient();
    core = _MockCoreHandler();
    when(() => core.validateConfig(any())).thenAnswer((_) async => null);
    storage = YoukoMixSessionStorage(homeDirProvider: () async => home.path);
    launchedUrls = [];
  });

  tearDown(() async {
    await storage.clearSession();
    await testDb.close();
  });

  ProviderContainer buildContainer({
    YoukoMixSession? initialSession,
    List<Profile> profiles = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        youkomixGateEnabledProvider.overrideWithValue(true),
        youkomixInitialSessionProvider.overrideWithValue(initialSession),
        youkomixApiProvider.overrideWithValue(api),
        youkomixStorageProvider.overrideWithValue(storage),
        youkomixUrlLauncherProvider.overrideWithValue((url) async {
          launchedUrls.add(url);
          return true;
        }),
        profilesProvider.overrideWith(() => TestProfiles(profiles)),
        coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
        setupActionProvider.overrideWith(_IdleSetupAction.new),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container.listen(youkomixControllerProvider, (_, _) {});
    container.listen(currentProfileIdProvider, (_, _) {});
    return container;
  }

  test(
    'login authenticates, saves session, and syncs managed profile',
    () async {
      final session = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_tok_1',
        expiresAt: 1999999999,
        bootstrap: _bootstrap(),
      );
      when(
        () => api.login(
          serverUrl: 'https://panel.example.com',
          email: 'reimu@example.com',
          password: 'pass',
        ),
      ).thenAnswer((_) async => YoukoMixLoginAuthenticated(session));
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_tok_1',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer((_) async => _payload());

      final container = buildContainer(
        profiles: const [
          Profile(
            id: 99,
            label: 'Rogue',
            autoUpdateDuration: Duration(hours: 6),
          ),
        ],
      );
      final ok = await container
          .read(youkomixControllerProvider.notifier)
          .login(
            serverUrl: 'panel.example.com',
            email: 'reimu@example.com',
            password: 'pass',
          );

      expect(ok, isTrue);
      final state = container.read(youkomixControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.user?.userName, '博丽灵梦');
      expect(container.read(profilesProvider).map((p) => p.id), [
        youkomixManagedProfileId,
      ]);
      expect(container.read(profilesProvider).single.label, '人间之里 · 专属订阅');
      expect((await storage.loadSession())?.accessToken, 'ymx_tok_1');
    },
  );

  test(
    'MFA challenge, expired challenge reset, and CAPTCHA browser handoff',
    () async {
      when(
        () => api.login(
          serverUrl: 'https://panel.example.com',
          email: 'mfa@example.com',
          password: 'pass',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixLoginMfaRequired(
          challengeToken: 'mfa_chal_1',
          webAuthUrl: 'https://panel.example.com/user/client-auth',
        ),
      );
      when(
        () => api.verifyMfa(
          serverUrl: 'https://panel.example.com',
          challengeToken: 'mfa_chal_1',
          code: '000000',
        ),
      ).thenThrow(
        const YoukoMixApiException(
          message: '验证已过期',
          errorCode: 'mfa_expired',
          statusCode: 401,
        ),
      );

      final container = buildContainer();
      final notifier = container.read(youkomixControllerProvider.notifier);

      expect(
        await notifier.login(
          serverUrl: 'https://panel.example.com',
          email: 'mfa@example.com',
          password: 'pass',
        ),
        isFalse,
      );
      expect(container.read(youkomixControllerProvider).isMfaStep, isTrue);

      expect(await notifier.verifyMfa('000000'), isFalse);
      expect(container.read(youkomixControllerProvider).isMfaStep, isFalse);
      expect(container.read(youkomixControllerProvider).errorMessage, '验证已过期');

      when(
        () => api.login(
          serverUrl: 'https://panel.example.com',
          email: 'cap@example.com',
          password: 'pass',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixLoginCaptchaRequired(
          webAuthUrl: 'https://panel.example.com/user/client-auth',
          message: '请在浏览器完成验证',
        ),
      );
      expect(
        await notifier.login(
          serverUrl: 'https://panel.example.com',
          email: 'cap@example.com',
          password: 'pass',
        ),
        isFalse,
      );
      expect(launchedUrls, ['https://panel.example.com/user/client-auth']);

      // Inline graphical CAPTCHA keeps login inside the app without browser launch.
      launchedUrls.clear();
      final inlineChallenge = YoukoMixCaptchaChallenge.fromJson(const {
        'captcha_id': 'cch_prov_1',
        'image_base64': tinyValidPngBase64,
        'expires_in': 180,
      });
      when(
        () => api.login(
          serverUrl: 'https://panel.example.com',
          email: 'inline@example.com',
          password: 'pass',
        ),
      ).thenAnswer(
        (_) async => YoukoMixLoginCaptchaRequired(
          challenge: inlineChallenge,
          webAuthUrl: 'https://panel.example.com/user/client-auth',
          message: '请输入图形验证码',
        ),
      );
      expect(
        await notifier.login(
          serverUrl: 'https://panel.example.com',
          email: 'inline@example.com',
          password: 'pass',
        ),
        isFalse,
      );
      expect(launchedUrls, isEmpty);
      expect(
        container.read(youkomixControllerProvider).captchaChallenge?.captchaId,
        'cch_prov_1',
      );

      // Switching server URL invalidates previous server's CAPTCHA challenge.
      notifier.setServerUrl('https://another-panel.example.com');
      expect(
        container.read(youkomixControllerProvider).captchaChallenge,
        isNull,
      );

      // Returning challenge == null clears any stale CAPTCHA challenge.
      notifier.setServerUrl('https://panel.example.com');
      await notifier.login(
        serverUrl: 'https://panel.example.com',
        email: 'inline@example.com',
        password: 'pass',
      );
      expect(
        container.read(youkomixControllerProvider).captchaChallenge?.captchaId,
        'cch_prov_1',
      );
      when(
        () => api.login(
          serverUrl: 'https://panel.example.com',
          email: 'webonly@example.com',
          password: 'pass',
          captchaId: 'cch_prov_1',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixLoginCaptchaRequired(
          webAuthUrl: 'https://panel.example.com/user/client-auth',
          message: '硬件密钥需网页验证',
        ),
      );
      await notifier.login(
        serverUrl: 'https://panel.example.com',
        email: 'webonly@example.com',
        password: 'pass',
      );
      expect(
        container.read(youkomixControllerProvider).captchaChallenge,
        isNull,
      );
    },
  );

  test(
    'deep link auth exchange, sync deep link, 401 sign-out, and logout',
    () async {
      final session = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_exchange',
        expiresAt: 1999999999,
        bootstrap: _bootstrap(),
      );
      when(
        () => api.exchangeCode(
          serverUrl: 'https://panel.example.com',
          code: 'ymxc_code_1',
        ),
      ).thenAnswer((_) async => session);
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_exchange',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer((_) async => _payload());
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_exchange',
        ),
      ).thenAnswer((_) async => _bootstrap());
      when(
        () => api.logout(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_exchange',
        ),
      ).thenAnswer((_) async {});

      final container = buildContainer();
      final notifier = container.read(youkomixControllerProvider.notifier);

      expect(
        await notifier.handleRawDeepLink('clash://install-config?url=x'),
        isFalse,
      );
      expect(
        await notifier.handleRawDeepLink(
          'youkomix://auth?code=ymxc_code_1&server=https%3A%2F%2Fpanel.example.com',
        ),
        isTrue,
      );
      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isTrue,
      );

      expect(await notifier.handleRawDeepLink('youkomix://sync'), isTrue);

      // Unauthenticated proxy 401 does NOT force sign-out.
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_exchange',
        ),
      ).thenThrow(
        const YoukoMixApiException(
          message: 'Bad proxy 401',
          errorCode: 'unauthorized',
          statusCode: 401,
          fromAuthenticatedEnvelope: false,
        ),
      );
      expect(await notifier.syncSubscription(), isFalse);
      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isTrue,
      );

      // Authenticated E2EE 401 DOES sign out and wipe local profile.
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_exchange',
        ),
      ).thenThrow(
        const YoukoMixApiException(
          message: 'Unauthorized',
          errorCode: 'unauthorized',
          statusCode: 401,
          fromAuthenticatedEnvelope: true,
        ),
      );
      expect(await notifier.syncSubscription(), isFalse);
      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isFalse,
      );
      expect(container.read(profilesProvider), isEmpty);
      expect(await storage.loadSession(), isNull);

      when(
        () => api.exchangeCode(
          serverUrl: 'https://panel.example.com',
          code: 'ymxc_code_2',
        ),
      ).thenAnswer((_) async => session);
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_exchange',
        ),
      ).thenAnswer((_) async => _bootstrap());
      await notifier.exchangeCode(
        code: 'ymxc_code_2',
        serverUrl: 'https://panel.example.com',
      );
      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isTrue,
      );

      await notifier.logout();
      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isFalse,
      );
      expect(container.read(profilesProvider), isEmpty);
      verify(
        () => api.logout(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_exchange',
        ),
      ).called(1);
    },
  );

  test(
    'switches between exclusive and standard subscription modes, persists choice, and falls back when exclusive is revoked',
    () async {
      final session = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_switch_tok',
        expiresAt: 1999999999,
        bootstrap: _bootstrap(),
      );
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_switch_tok',
        ),
      ).thenAnswer((_) async => _bootstrap());
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_switch_tok',
          mode: 'standard',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer(
        (_) async => YoukoMixSubscriptionPayload(
          bytes: Uint8List.fromList(
            utf8.encode('proxies:\n  - {name: STD-01, type: ss}\n'),
          ),
          mode: 'standard',
          title: '人间之里',
          updateIntervalHours: 6,
        ),
      );
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_switch_tok',
          mode: 'exclusive',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer((_) async => _payload());

      final container = buildContainer(
        initialSession: session,
        profiles: const [
          Profile(
            id: youkomixManagedProfileId,
            label: '人间之里 · 专属订阅',
            selectedMap: {'Proxy': 'HK-01'},
            currentGroupName: 'Proxy',
            autoUpdateDuration: Duration(hours: 6),
          ),
        ],
      );
      final notifier = container.read(youkomixControllerProvider.notifier);

      expect(
        container.read(youkomixControllerProvider).isExclusiveActive,
        isTrue,
      );

      // Pinning exclusive while already active preserves existing group selection.
      expect(
        await notifier.switchSubscriptionMode(YoukoMixSubPreference.exclusive),
        isTrue,
      );
      expect(container.read(profilesProvider).single.selectedMap, const {
        'Proxy': 'HK-01',
      });

      final switchedToStd = await notifier.switchSubscriptionMode(
        YoukoMixSubPreference.standard,
      );
      expect(switchedToStd, isTrue);

      final afterStd = container.read(youkomixControllerProvider);
      expect(afterStd.isExclusiveActive, isFalse);
      expect(afterStd.preferredSubMode, YoukoMixSubPreference.standard);
      expect(afterStd.subscription?.exclusiveEnabled, isTrue);
      expect(afterStd.subscription?.activeMode, 'standard');

      final stdProfile = container.read(profilesProvider).single;
      expect(stdProfile.label, '人间之里');
      expect(stdProfile.selectedMap, isEmpty);
      expect(stdProfile.currentGroupName, isNull);

      final persistedStd = await storage.loadSession();
      expect(persistedStd?.preferredSubMode, YoukoMixSubPreference.standard);

      // Re-invoking a deep link with the same mode still performs a fresh sync.
      clearInteractions(api);
      expect(
        await notifier.handleRawDeepLink('youkomix://sync?mode=standard'),
        isTrue,
      );
      verify(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_switch_tok',
          mode: 'standard',
          userAgent: any(named: 'userAgent'),
        ),
      ).called(1);

      // Subsequent regular sync preserves standard mode without reverting to exclusive.
      expect(await notifier.syncSubscription(), isTrue);
      expect(
        container.read(youkomixControllerProvider).isExclusiveActive,
        isFalse,
      );

      // Switch back to exclusive via deep link.
      expect(
        await notifier.handleRawDeepLink('youkomix://sync?mode=exclusive'),
        isTrue,
      );
      expect(
        container.read(youkomixControllerProvider).isExclusiveActive,
        isTrue,
      );
      expect(container.read(profilesProvider).single.label, '人间之里 · 专属订阅');

      // If panel later revokes exclusive subscription, sync falls back cleanly to auto/standard.
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_switch_tok',
        ),
      ).thenAnswer(
        (_) async => _bootstrap().copyWith(
          subscription: const YoukoMixSubscriptionState(
            exclusiveEnabled: false,
            activeMode: 'standard',
          ),
        ),
      );
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_switch_tok',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer(
        (_) async => YoukoMixSubscriptionPayload(
          bytes: Uint8List.fromList(
            utf8.encode('proxies:\n  - {name: STD-01, type: ss}\n'),
          ),
          mode: 'standard',
          title: '人间之里',
          updateIntervalHours: 6,
        ),
      );

      expect(await notifier.syncSubscription(), isTrue);
      final afterRevoke = container.read(youkomixControllerProvider);
      expect(afterRevoke.isExclusiveActive, isFalse);
      expect(afterRevoke.preferredSubMode, YoukoMixSubPreference.auto);
    },
  );

  test(
    'refreshBootstrapIfNeeded updates account state without re-downloading config and tracks unread announcements',
    () async {
      const initial = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_boot_tok',
        expiresAt: 1999999999,
        bootstrap: YoukoMixBootstrap(
          user: YoukoMixUser(
            id: 1,
            userName: '博丽灵梦',
            userClass: 1,
            money: '10.00',
            onlineIpCount: 1,
            nodeIpLimit: 3,
          ),
          subscription: YoukoMixSubscriptionState(
            exclusiveEnabled: false,
            activeMode: 'standard',
          ),
        ),
      );
      when(() => api.fetchMeta('https://panel.example.com')).thenAnswer(
        (_) async => const YoukoMixMeta(
          baseUrl: 'https://panel.example.com',
          minClientVersion: '2.0.0',
        ),
      );
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_boot_tok',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixBootstrap(
          user: YoukoMixUser(
            id: 1,
            userName: '博丽灵梦',
            userClass: 2,
            money: '88.00',
            onlineIpCount: 2,
            nodeIpLimit: 3,
            nodeSpeedLimit: 500,
          ),
          subscription: YoukoMixSubscriptionState(
            exclusiveEnabled: false,
            activeMode: 'standard',
          ),
          announcements: [
            YoukoMixAnnouncement(
              id: 12,
              title: '重要更新',
              markdown: '## 升级提示\n请及时同步配置',
              isPinned: true,
            ),
          ],
          links: YoukoMixLinks(panelUrl: 'https://panel.example.com/user'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          youkomixGateEnabledProvider.overrideWithValue(true),
          youkomixInitialSessionProvider.overrideWithValue(initial),
          youkomixCurrentAppVersionProvider.overrideWithValue('1.2.0'),
          youkomixApiProvider.overrideWithValue(api),
          youkomixStorageProvider.overrideWithValue(storage),
          profilesProvider.overrideWith(
            () => TestProfiles(const [
              Profile(
                id: youkomixManagedProfileId,
                label: '人间之里',
                autoUpdateDuration: Duration(hours: 6),
              ),
            ]),
          ),
          coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
          setupActionProvider.overrideWith(_IdleSetupAction.new),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container.listen(youkomixControllerProvider, (_, _) {});

      final notifier = container.read(youkomixControllerProvider.notifier);
      expect(await notifier.refreshBootstrapIfNeeded(), isTrue);
      // Throttled within minInterval unless forced.
      expect(await notifier.refreshBootstrapIfNeeded(), isFalse);
      verifyNever(
        () => api.downloadSubscription(
          serverUrl: any(named: 'serverUrl'),
          accessToken: any(named: 'accessToken'),
          mode: any(named: 'mode'),
          userAgent: any(named: 'userAgent'),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      final updated = container.read(youkomixControllerProvider);
      expect(updated.user?.money, '88.00');
      expect(updated.user?.nodeSpeedLimit, 500);
      expect(updated.hasUnreadAnnouncements, isTrue);
      expect(updated.pendingPinnedAnnouncement?.id, 12);
      expect(updated.isClientOutdated, isTrue);
      expect(
        updated.resolvePanelSubpath('/user/shop'),
        'https://panel.example.com/user/shop',
      );
      expect(
        updated.resolvePanelSubpath('/user/ticket'),
        'https://panel.example.com/user/ticket',
      );

      final diag = notifier.buildDiagnosticSummary(
        isTunEnabled: true,
        isSystemProxyEnabled: false,
      );
      expect(diag, contains('YoukoMix v1.2.0'));
      expect(diag, contains('Mode: TUN'));
      expect(diag, contains('Devices: 2/3'));
      expect(diag, isNot(contains('ymx_boot_tok')));
      expect(diag, isNot(contains('panel.example.com')));

      await notifier.acknowledgePinnedAnnouncement(12);
      final afterAck = container.read(youkomixControllerProvider);
      expect(afterAck.hasUnreadAnnouncements, isFalse);
      expect(afterAck.pendingPinnedAnnouncement, isNull);
    },
  );

  test(
    'suppresses plan expiry in non-commercial mode and executes native daily check-in',
    () async {
      const nonCommercialSession = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_free_tok',
        expiresAt: 1999999999,
        bootstrap: YoukoMixBootstrap(
          user: YoukoMixUser(
            id: 1,
            userName: '雾雨魔理沙',
            userClass: 0,
            classExpire: '1983-08-25 00:05:00',
            classExpireDays: 0,
            isExpired: true,
          ),
          traffic: YoukoMixTraffic(
            upload: 512 * 1024 * 1024,
            download: 512 * 1024 * 1024,
            total: 2 * 1024 * 1024 * 1024,
            remaining: 1024 * 1024 * 1024,
          ),
          commerce: YoukoMixCommerce(enabled: false, freeResetDay: 1),
          features: YoukoMixFeatures(
            regMode: 'close',
            ticketEnabled: false,
            checkinEnabled: true,
            checkinCaptchaEnabled: false,
            ableToCheckin: true,
          ),
          links: YoukoMixLinks(panelUrl: 'https://panel.example.com/user'),
        ),
      );

      when(
        () => api.checkin(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_free_tok',
        ),
      ).thenAnswer(
        (_) async => YoukoMixCheckinResult(
          trafficMb: 256,
          message: '签到成功，获得 256 MB 流量',
          bootstrap: nonCommercialSession.bootstrap!.copyWith(
            traffic: const YoukoMixTraffic(
              upload: 512 * 1024 * 1024,
              download: 512 * 1024 * 1024,
              total: 2304 * 1024 * 1024,
              remaining: 1280 * 1024 * 1024,
            ),
            features: nonCommercialSession.bootstrap!.features.copyWith(
              ableToCheckin: false,
            ),
          ),
        ),
      );

      final container = buildContainer(
        initialSession: nonCommercialSession,
        profiles: const [
          Profile(
            id: youkomixManagedProfileId,
            label: '人间之里',
            autoUpdateDuration: Duration(hours: 6),
            subscriptionInfo: SubscriptionInfo(
              upload: 512 * 1024 * 1024,
              download: 512 * 1024 * 1024,
              total: 2 * 1024 * 1024 * 1024,
              expire: 430589100,
            ),
          ),
        ],
      );
      final initialState = container.read(youkomixControllerProvider);
      expect(initialState.isCommerceEnabled, isFalse);
      expect(initialState.isPlanExpiredOrInactive, isFalse);
      expect(initialState.isQuotaOrExpiryWarning, isFalse);
      expect(initialState.canRegister, isFalse);
      expect(initialState.isTicketEnabled, isFalse);

      final ok = await container
          .read(youkomixControllerProvider.notifier)
          .checkin();
      expect(ok, isTrue);

      final afterCheckin = container.read(youkomixControllerProvider);
      expect(afterCheckin.features.ableToCheckin, isFalse);
      expect(afterCheckin.traffic?.total, 2304 * 1024 * 1024);
      final updatedProfile = container
          .read(profilesProvider)
          .getProfile(youkomixManagedProfileId);
      expect(updatedProfile?.subscriptionInfo?.expire, 0);
      expect(updatedProfile?.subscriptionInfo?.total, 2304 * 1024 * 1024);
    },
  );
}
