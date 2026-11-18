import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/youkomix/youkomix.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prism_ui/prism_ui.dart';

import '../helpers/app_paths.dart';
import '../helpers/host_scaffold.dart';
import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

class _MockApiClient extends Mock implements YoukoMixApiClient {}

class _MockCoreHandler extends Mock implements CoreHandlerInterface {}

class _MemorySessionStorage extends YoukoMixSessionStorage {
  YoukoMixSession? saved;

  @override
  Future<YoukoMixSession?> loadSession() async => saved;

  @override
  Future<void> saveSession(YoukoMixSession session) async {
    saved = session;
    setActiveServerUrl(session.serverUrl);
  }

  @override
  Future<void> clearSession() async {
    saved = null;
  }
}

class _MemoryProfilesAction extends ProfilesAction {
  @override
  Future<void> purgeUnmanagedProfiles() async {}

  @override
  Future<void> clearAllProfiles() async {
    ref.read(profilesProvider.notifier).reorder(const []);
    ref.read(currentProfileIdProvider.notifier).value = null;
  }

  @override
  Future<Profile> saveManagedProfile({
    required Uint8List bytes,
    required String label,
    required SubscriptionInfo subscriptionInfo,
    Duration autoUpdateDuration = const Duration(hours: 6),
    bool resetSelection = false,
  }) async {
    final saved = Profile(
      id: youkomixManagedProfileId,
      type: ProfileType.file,
      label: label,
      autoUpdate: true,
      autoUpdateDuration: autoUpdateDuration,
      subscriptionInfo: subscriptionInfo,
    );
    ref.read(profilesProvider.notifier).put(saved);
    ref.read(currentProfileIdProvider.notifier).value =
        youkomixManagedProfileId;
    return saved;
  }
}

class _IdleSetupAction extends SetupAction {
  @override
  void applyProfileDebounce({bool silence = false, bool force = false}) {}

  @override
  Future<bool> setRunning(bool isRun, {bool initialize = false}) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory home;
  late Database testDb;
  late _MockApiClient api;
  late _MockCoreHandler core;
  late _MemorySessionStorage storage;
  late List<String> launchedUrls;

  setUpAll(() async {
    home = Directory.systemTemp.createTempSync('youkomix-account-sheet-');
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
    when(() => core.clearEffect(any())).thenAnswer((_) async {});
    when(() => core.validateConfig(any())).thenAnswer((_) async => null);
    when(
      () => api.fetchBootstrap(
        serverUrl: any(named: 'serverUrl'),
        accessToken: any(named: 'accessToken'),
      ),
    ).thenAnswer(
      (_) async => const YoukoMixBootstrap(
        user: YoukoMixUser(
          id: 1,
          email: 'reimu@example.com',
          userName: '博丽灵梦',
          userClass: 2,
          classExpire: '2028-01-01 00:00:00',
          classExpireDays: 365,
          money: '42.00',
        ),
        subscription: YoukoMixSubscriptionState(
          exclusiveEnabled: true,
          activeMode: 'exclusive',
        ),
        announcements: [
          YoukoMixAnnouncement(
            id: 10,
            date: '2026-11-15',
            title: '新节点上线',
            markdown: '新增东京与香港专线节点',
            isPinned: true,
          ),
        ],
        links: YoukoMixLinks(panelUrl: 'https://panel.example.com/user'),
      ),
    );
    when(
      () => api.downloadSubscription(
        serverUrl: any(named: 'serverUrl'),
        accessToken: any(named: 'accessToken'),
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
      ),
    );
    when(
      () => api.logout(
        serverUrl: any(named: 'serverUrl'),
        accessToken: any(named: 'accessToken'),
      ),
    ).thenAnswer((_) async {});
    storage = _MemorySessionStorage();
    launchedUrls = [];
  });

  tearDown(() async {
    await storage.clearSession();
    await testDb.close();
  });

  testWidgets(
    'renders account details, announcements sheet, panel link, and logout',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const session = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_acc_token',
        expiresAt: 1999999999,
        bootstrap: YoukoMixBootstrap(
          user: YoukoMixUser(
            id: 1,
            email: 'reimu@example.com',
            userName: '博丽灵梦',
            userClass: 2,
            classExpire: '2028-01-01 00:00:00',
            classExpireDays: 365,
            money: '42.00',
          ),
          subscription: YoukoMixSubscriptionState(
            exclusiveEnabled: true,
            activeMode: 'exclusive',
          ),
          commerce: YoukoMixCommerce(
            enabled: true,
            products: true,
            balance: true,
            shopUrl: 'https://panel.example.com/user/product',
          ),
          announcements: [
            YoukoMixAnnouncement(
              id: 10,
              date: '2026-11-15',
              title: '新节点上线',
              markdown: '新增东京与香港专线节点',
              isPinned: true,
            ),
          ],
          links: YoukoMixLinks(panelUrl: 'https://panel.example.com/user'),
        ),
      );
      const profile = Profile(
        id: youkomixManagedProfileId,
        label: '人间之里 · 专属订阅',
        autoUpdateDuration: Duration(hours: 6),
        subscriptionInfo: SubscriptionInfo(
          upload: 1024 * 1024 * 1024,
          download: 3 * 1024 * 1024 * 1024,
          total: 10 * 1024 * 1024 * 1024,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          youkomixGateEnabledProvider.overrideWithValue(true),
          youkomixInitialSessionProvider.overrideWithValue(session),
          youkomixApiProvider.overrideWithValue(api),
          youkomixStorageProvider.overrideWithValue(storage),
          youkomixUrlLauncherProvider.overrideWithValue((url) async {
            launchedUrls.add(url);
            return true;
          }),
          profilesProvider.overrideWith(() => TestProfiles([profile])),
          profilesActionProvider.overrideWith(_MemoryProfilesAction.new),
          currentProfileIdProvider.overrideWithBuild(
            (_, _) => youkomixManagedProfileId,
          ),
          coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
          setupActionProvider.overrideWith(_IdleSetupAction.new),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container.read(viewSizeProvider.notifier).value = const Size(1200, 1000);

      var runtimeDetailTapped = false;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(
            child: Builder(
              builder: (context) => HostScaffold(
                body: TextButton(
                  onPressed: () => showYoukoMixAccountSheet(
                    context,
                    onShowRuntimeDetail: () => runtimeDetailTapped = true,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;

      expect(find.text('博丽灵梦'), findsOneWidget);
      expect(find.text('reimu@example.com'), findsOneWidget);
      expect(find.text('Lv.2'), findsOneWidget);
      expect(find.text('¥42.00'), findsOneWidget);
      expect(find.text('新节点上线'), findsOneWidget);
      expect(find.text(l10n.youkomixSubChannel), findsOneWidget);
      expect(find.text(l10n.youkomixSubChannelStandard), findsOneWidget);

      await tester.tap(find.text(l10n.youkomixSubChannelStandard));
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(
        container.read(youkomixControllerProvider).isExclusiveActive,
        isFalse,
      );
      expect(find.text(l10n.youkomixSubModeExclusive), findsNothing);
      expect(find.text(l10n.youkomixSubModeStandard), findsNWidgets(2));

      await tester.tap(find.byTooltip(l10n.youkomixOpenPanel));
      await tester.pumpAndSettle();
      expect(launchedUrls, ['https://panel.example.com/user']);

      await tester.tap(find.text('新节点上线'));
      await tester.pumpAndSettle();
      expect(find.byType(YoukoMixAnnouncementsSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(YoukoMixAnnouncementsSheet),
          matching: find.text('新增东京与香港专线节点'),
        ),
        findsOneWidget,
      );

      globalState.navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(l10n.runtimeConfig),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(l10n.runtimeConfig));
      await tester.pumpAndSettle();
      expect(runtimeDetailTapped, isTrue);

      await tester.scrollUntilVisible(
        find.text(l10n.youkomixLogout),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(l10n.youkomixLogout));
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.text(l10n.youkomixLogout),
            )
            .last,
      );
      await tester.pump();
      for (var i = 0; i < 80; i++) {
        final state = container.read(youkomixControllerProvider);
        if (!state.isBusy && !state.isSyncing && !state.isAuthenticated) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isFalse,
      );
    },
  );

  testWidgets(
    'renders X25519MLKEM768 upgrade notice card and syncs configuration on tap',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const notice = YoukoMixUpgradeNotice(
        enabled: true,
        mode: 'required',
        cutoverAt: 1795204020,
        title: '开启 X25519MLKEM768 更新通知',
        message: '系统已全面开启 X25519MLKEM768 支持，若遇到连接异常，请将客户端及本地配置更新至最新版本。',
      );
      const session = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_acc_token',
        expiresAt: 1999999999,
        bootstrap: YoukoMixBootstrap(
          user: YoukoMixUser(
            id: 1,
            email: 'reimu@example.com',
            userName: '博丽灵梦',
            userClass: 2,
          ),
          subscription: YoukoMixSubscriptionState(
            exclusiveEnabled: false,
            activeMode: 'standard',
          ),
          upgradeNotice: notice,
        ),
      );
      when(
        () => api.downloadSubscription(
          serverUrl: any(named: 'serverUrl'),
          accessToken: any(named: 'accessToken'),
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer(
        (_) async => YoukoMixSubscriptionPayload(
          bytes: Uint8List.fromList(
            utf8.encode('proxies:\n  - {name: STD-01, type: ss}\n'),
          ),
          mode: 'standard',
          title: '人间之里',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          youkomixGateEnabledProvider.overrideWithValue(true),
          youkomixInitialSessionProvider.overrideWithValue(session),
          youkomixApiProvider.overrideWithValue(api),
          youkomixStorageProvider.overrideWithValue(storage),
          profilesProvider.overrideWith(() => TestProfiles(const [])),
          profilesActionProvider.overrideWith(_MemoryProfilesAction.new),
          coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
          setupActionProvider.overrideWith(_IdleSetupAction.new),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container.read(viewSizeProvider.notifier).value = const Size(1200, 1000);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(
            child: Builder(
              builder: (context) => HostScaffold(
                body: TextButton(
                  onPressed: () => showYoukoMixAccountSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.current;
      expect(find.text('开启 X25519MLKEM768 更新通知'), findsOneWidget);
      expect(
        find.text('系统已全面开启 X25519MLKEM768 支持，若遇到连接异常，请将客户端及本地配置更新至最新版本。'),
        findsOneWidget,
      );
      expect(container.read(youkomixControllerProvider).upgradeNotice, notice);

      await tester.tap(find.text(l10n.sync));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      verify(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_acc_token',
          userAgent: any(named: 'userAgent'),
        ),
      ).called(1);
    },
  );

  testWidgets(
    'renders rich Markdown announcements without raw syntax, device/speed metrics, renewal CTA, and ticket action',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const session = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_acc_token',
        expiresAt: 1999999999,
        bootstrap: YoukoMixBootstrap(
          user: YoukoMixUser(
            id: 1,
            email: 'reimu@example.com',
            userName: '博丽灵梦',
            userClass: 1,
            isExpired: true,
            onlineIpCount: 3,
            nodeIpLimit: 3,
            nodeSpeedLimit: 200,
          ),
          traffic: YoukoMixTraffic(
            upload: 1024 * 1024 * 1024,
            download: 2 * 1024 * 1024 * 1024,
            today: 512 * 1024 * 1024,
            total: 10 * 1024 * 1024 * 1024,
          ),
          subscription: YoukoMixSubscriptionState(
            exclusiveEnabled: false,
            activeMode: 'standard',
          ),
          commerce: YoukoMixCommerce(
            enabled: true,
            products: true,
            balance: true,
            shopUrl: 'https://panel.example.com/user/product',
          ),
          announcements: [
            YoukoMixAnnouncement(
              id: 25,
              date: '2026-11-18',
              title: '系统升级公告',
              markdown:
                  '## 一、升级时间\n将于 **72 小时后** 全面开启 `X25519MLKEM768`。\n- 第一步：更新客户端\n- 第二步：同步配置',
              isPinned: true,
            ),
          ],
          links: YoukoMixLinks(panelUrl: 'https://panel.example.com/user'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          youkomixGateEnabledProvider.overrideWithValue(true),
          youkomixInitialSessionProvider.overrideWithValue(session),
          youkomixApiProvider.overrideWithValue(api),
          youkomixStorageProvider.overrideWithValue(storage),
          youkomixUrlLauncherProvider.overrideWithValue((url) async {
            launchedUrls.add(url);
            return true;
          }),
          profilesProvider.overrideWith(
            () => TestProfiles(const [
              Profile(
                id: youkomixManagedProfileId,
                label: '人间之里',
                autoUpdateDuration: Duration(hours: 6),
                subscriptionInfo: SubscriptionInfo(
                  upload: 1024 * 1024 * 1024,
                  download: 2 * 1024 * 1024 * 1024,
                  total: 10 * 1024 * 1024 * 1024,
                ),
              ),
            ]),
          ),
          currentProfileIdProvider.overrideWithBuild(
            (_, _) => youkomixManagedProfileId,
          ),
          profilesActionProvider.overrideWith(_MemoryProfilesAction.new),
          coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
          setupActionProvider.overrideWith(_IdleSetupAction.new),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container.read(viewSizeProvider.notifier).value = const Size(1200, 1100);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(
            child: Builder(
              builder: (context) => HostScaffold(
                body: TextButton(
                  onPressed: () => showYoukoMixAccountSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.current;
      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.text('200 Mbps'), findsOneWidget);
      expect(find.text(l10n.youkomixRenewPlan), findsOneWidget);

      await tester.tap(find.text(l10n.youkomixRenewPlan));
      await tester.pumpAndSettle();
      expect(launchedUrls.last, 'https://panel.example.com/user/product');

      await tester.scrollUntilVisible(
        find.text(l10n.youkomixSubmitTicket),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(l10n.youkomixSubmitTicket));
      await tester.pumpAndSettle();
      expect(launchedUrls.last, 'https://panel.example.com/user/ticket');

      await tester.tap(find.text('系统升级公告'));
      await tester.pumpAndSettle();
      expect(find.byType(YoukoMixAnnouncementsSheet), findsOneWidget);
      expect(find.textContaining('##'), findsNothing);
      expect(find.textContaining('**'), findsNothing);
      expect(find.text('X25519MLKEM768'), findsOneWidget);
      expect(
        container.read(youkomixControllerProvider).hasUnreadAnnouncements,
        isFalse,
      );
    },
  );

  testWidgets(
    'non-commercial mode hides plan expiry/balance/Lv.0, hides disabled ticket row, and supports native daily check-in',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const session = YoukoMixSession(
        serverUrl: 'https://panel.example.com',
        accessToken: 'ymx_free_token',
        expiresAt: 1999999999,
        bootstrap: YoukoMixBootstrap(
          user: YoukoMixUser(
            id: 1,
            email: 'marisa@example.com',
            userName: '雾雨魔理沙',
            userClass: 0,
            classExpire: '1983-08-25 00:05:00',
            isExpired: true,
            money: '0.00',
            onlineIpCount: 1,
            nodeIpLimit: 2,
          ),
          traffic: YoukoMixTraffic(
            upload: 5 * 1024 * 1024 * 1024,
            download: 5 * 1024 * 1024 * 1024,
            total: 10 * 1024 * 1024 * 1024,
            remaining: 0,
          ),
          commerce: YoukoMixCommerce(enabled: false, freeResetDay: 15),
          features: YoukoMixFeatures(
            ticketEnabled: false,
            checkinEnabled: true,
            ableToCheckin: true,
          ),
          links: YoukoMixLinks(panelUrl: 'https://panel.example.com/user'),
        ),
      );

      when(
        () => api.checkin(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_free_token',
        ),
      ).thenAnswer(
        (_) async => YoukoMixCheckinResult(
          trafficMb: 512,
          message: '签到成功，获得 512 MB 流量',
          bootstrap: session.bootstrap!.copyWith(
            traffic: const YoukoMixTraffic(
              upload: 5 * 1024 * 1024 * 1024,
              download: 5 * 1024 * 1024 * 1024,
              total: 10752 * 1024 * 1024,
              remaining: 512 * 1024 * 1024,
            ),
            features: session.bootstrap!.features.copyWith(
              ableToCheckin: false,
            ),
          ),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          youkomixGateEnabledProvider.overrideWithValue(true),
          youkomixInitialSessionProvider.overrideWithValue(session),
          youkomixApiProvider.overrideWithValue(api),
          youkomixStorageProvider.overrideWithValue(storage),
          profilesProvider.overrideWith(
            () => TestProfiles(const [
              Profile(
                id: youkomixManagedProfileId,
                label: '人间之里',
                autoUpdateDuration: Duration(hours: 6),
                subscriptionInfo: SubscriptionInfo(
                  upload: 5 * 1024 * 1024 * 1024,
                  download: 5 * 1024 * 1024 * 1024,
                  total: 10 * 1024 * 1024 * 1024,
                  expire: 430589100,
                ),
              ),
            ]),
          ),
          currentProfileIdProvider.overrideWithBuild(
            (_, _) => youkomixManagedProfileId,
          ),
          profilesActionProvider.overrideWith(_MemoryProfilesAction.new),
          coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
          setupActionProvider.overrideWith(_IdleSetupAction.new),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container.read(viewSizeProvider.notifier).value = const Size(1200, 1100);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(
            child: Builder(
              builder: (context) => HostScaffold(
                body: TextButton(
                  onPressed: () => showYoukoMixAccountSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.current;
      expect(find.text('Lv.0'), findsNothing);
      expect(find.text('¥0.00'), findsNothing);
      expect(find.text(l10n.youkomixBalance), findsNothing);
      expect(find.text(l10n.expireTime), findsNothing);
      expect(find.text(l10n.youkomixExpired), findsNothing);
      expect(find.text(l10n.youkomixRenewPlan), findsNothing);
      expect(find.textContaining('1983'), findsNothing);
      expect(find.text(l10n.youkomixSubmitTicket), findsNothing);
      expect(
        find.text(l10n.youkomixFreeQuotaExhaustedResetDesc(15)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('youkomix-checkin-button')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('youkomix-checkin-button')));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(
        find.byKey(const ValueKey('youkomix-checked-in-pill')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.youkomixFreeQuotaExhaustedResetDesc(15)),
        findsNothing,
      );
    },
  );
}
