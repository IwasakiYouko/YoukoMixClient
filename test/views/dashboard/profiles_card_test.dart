import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/youkomix/youkomix.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/views/dashboard/style.dart';
import 'package:fl_clash/views/dashboard/widgets/profile_detail.dart';
import 'package:fl_clash/views/dashboard/widgets/profiles.dart';
import 'package:fl_clash/views/proxies/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

import '../../helpers/app_paths.dart';
import '../../helpers/host_scaffold.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_profiles.dart';

const _gib = 1024 * 1024 * 1024;

ExternalProvider _provider(String name, String type, int count) =>
    ExternalProvider(
      name: name,
      type: type,
      count: count,
      vehicleType: 'HTTP',
      updateAt: DateTime(2026),
    );

Profile _profile(
  int id, {
  SubscriptionInfo? info,
  ProfileType type = ProfileType.file,
}) => Profile(
  id: id,
  label: 'P$id',
  type: type,
  url: '',
  autoUpdateDuration: Duration.zero,
  lastUpdateDate: DateTime.now().subtract(const Duration(minutes: 5)),
  subscriptionInfo: info,
);

YoukoMixSession _session({
  int userClass = 2,
  int expireDays = 30,
  bool isExpired = false,
  bool commerceEnabled = true,
  int onlineIpCount = 0,
  int nodeIpLimit = 0,
  String mode = 'exclusive',
  int total = 100 * _gib,
  int used = 42 * _gib,
}) {
  return YoukoMixSession(
    serverUrl: 'https://panel.example.com',
    accessToken: 'ymx_token',
    expiresAt: 1999999999,
    bootstrap: YoukoMixBootstrap(
      links: const YoukoMixLinks(
        panelUrl: 'https://panel.example.com/user',
        webAuthUrl: 'https://panel.example.com/user/client-auth',
      ),
      user: YoukoMixUser(
        id: 1,
        email: 'reimu@example.com',
        userName: '博丽灵梦',
        userClass: userClass,
        classExpire: '2027-01-01 00:00:00',
        classExpireDays: expireDays,
        isExpired: isExpired,
        money: '12.50',
        onlineIpCount: onlineIpCount,
        nodeIpLimit: nodeIpLimit,
      ),
      traffic: YoukoMixTraffic(
        upload: _gib,
        download: used - _gib,
        used: used,
        today: _gib,
        total: total,
        remaining: total - used,
      ),
      subscription: YoukoMixSubscriptionState(
        exclusiveEnabled: mode == 'exclusive',
        exclusiveTitle: '人间之里 · 专属订阅',
        activeMode: mode,
        updateIntervalHours: 6,
      ),
      commerce: YoukoMixCommerce(
        enabled: commerceEnabled,
        products: commerceEnabled,
        balance: commerceEnabled,
        shopUrl: 'https://panel.example.com/user/product',
      ),
    ),
  );
}

void main() {
  late ProviderContainer container;

  setUpAll(() async {
    final home = Directory.systemTemp.createTempSync('profiles_card');
    addTearDown(() => home.deleteSync(recursive: true));
    await useAppPaths(home);
  });

  void setUpProfiles(
    List<Profile> profiles, {
    YoukoMixSession? session,
    List<Override> overrides = const [],
  }) {
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles(profiles)),
        youkomixInitialSessionProvider.overrideWithValue(session),
        viewSizeProvider.overrideWithBuild((_, _) => const Size(1200, 1000)),
        ...overrides,
      ],
    );
    globalState.container = container;
    container.listen(currentProfileIdProvider, (_, _) {});
    container.read(currentProfileIdProvider.notifier).value =
        profiles.firstOrNull?.id;
    addTearDown(container.dispose);
  }

  Future<void> settleCounts(WidgetTester tester, {Finder? until}) async {
    bool done() => until != null
        ? until.evaluate().isNotEmpty
        : find.byType(SkeletonText).evaluate().isEmpty;
    for (var i = 0; i < 40 && !done(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    Widget card = const ProfilesCard(),
    double width = 360,
  }) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: HostScaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: card),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await settleCounts(tester);
  }

  Future<void> pumpDesktopCard(WidgetTester tester) => pumpCard(
    tester,
    card: const DashboardDensityScope(
      density: DashboardDensity.standard,
      scale: 1,
      child: SizedBox(height: 176, child: ProfilesCard()),
    ),
    width: 300,
  );

  Finder label(String text) => find.text(text, findRichText: true);

  testWidgets('shows login prompt without profiles or session', (tester) async {
    setUpProfiles([]);
    await pumpCard(tester);
    final l10n = AppLocalizations.current;

    expect(find.text(l10n.youkomixLogin), findsOneWidget);

    await pumpDesktopCard(tester);
    expect(find.text(l10n.youkomixLogin), findsOneWidget);
    expect(find.byTooltip('Switch profile'), findsNothing);
  });

  testWidgets(
    'shows authenticated YoukoMix account, level badge, quota, and opens account sheet',
    (tester) async {
      setUpProfiles([_profile(1)], session: _session());
      await pumpCard(tester);
      final l10n = AppLocalizations.current;

      expect(label('博丽灵梦'), findsOneWidget);
      expect(find.text('Lv.2'), findsOneWidget);
      expect(find.text(l10n.youkomixSubModeExclusive), findsOneWidget);
      expect(find.textContaining('42%', findRichText: true), findsOneWidget);
      expect(find.text('42 GB / 100 GB'), findsOneWidget);
      expect(find.textContaining('30 days left'), findsOneWidget);
      expect(find.byTooltip(l10n.youkomixSyncNodes), findsOneWidget);
      expect(find.byTooltip(l10n.youkomixSubChannel), findsOneWidget);

      await tester.tap(find.byTooltip(l10n.youkomixSubChannel));
      await tester.pumpAndSettle();
      expect(find.text(l10n.youkomixSubChannelStandard), findsOneWidget);
      // Dismiss popup menu before tapping account card.
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      await tester.tap(label('博丽灵梦'));
      await tester.pumpAndSettle();

      expect(find.byType(YoukoMixAccountSheet), findsOneWidget);
      expect(find.text('reimu@example.com'), findsOneWidget);
    },
  );

  testWidgets('shows expired warning on commercial sites and hides Lv.0', (
    tester,
  ) async {
    setUpProfiles(
      [],
      session: _session(
        userClass: 0,
        isExpired: true,
        commerceEnabled: true,
        total: 0,
        used: 0,
      ),
    );
    await pumpCard(tester);
    final l10n = AppLocalizations.current;

    expect(label('博丽灵梦'), findsOneWidget);
    expect(find.text('Lv.0'), findsNothing);
    expect(find.text(l10n.youkomixExpired), findsOneWidget);
    expect(find.text(l10n.youkomixOpenPanel), findsOneWidget);
  });

  testWidgets(
    'non-commercial desktop card suppresses expiry, displays active devices, and opens account sheet on card tap',
    (tester) async {
      setUpProfiles(
        [_profile(1)],
        session: _session(
          userClass: 0,
          isExpired: true,
          commerceEnabled: false,
          onlineIpCount: 1,
          nodeIpLimit: 2,
        ),
      );
      await pumpDesktopCard(tester);
      final l10n = AppLocalizations.current;

      expect(label('博丽灵梦'), findsOneWidget);
      expect(find.text('Lv.0'), findsNothing);
      expect(find.text(l10n.youkomixExpired), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(label('博丽灵梦'));
      await tester.pumpAndSettle();
      expect(find.byType(YoukoMixAccountSheet), findsOneWidget);
    },
  );

  Future<File> writeAppliedConfig(WidgetTester tester) async {
    final file = await tester.runAsync(() async {
      final file = File(await appPath.configFilePath);
      await file.writeAsString(
        'proxies:\n'
        '  - {name: a, type: ss}\n'
        '  - {name: b, type: ss}\n'
        'proxy-groups:\n'
        '  - {name: g, type: select, proxies: [a]}\n'
        'rules:\n'
        '  - MATCH,DIRECT\n'
        '  - DOMAIN,a.com,DIRECT\n'
        '  - GEOIP,CN,DIRECT\n',
      );
      return file;
    });
    addTearDown(() async {
      if (file!.existsSync()) file.deleteSync();
    });
    return file!;
  }

  Future<void> openRuntimeDetailFromAccount(WidgetTester tester) async {
    await tester.tap(label('博丽灵梦'));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.current;
    await tester.scrollUntilVisible(
      find.text(l10n.runtimeConfig),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text(l10n.runtimeConfig));
    await tester.pumpAndSettle();
    await settleCounts(tester, until: find.text('3'));
    await tester.pumpAndSettle();
  }

  testWidgets('reopening detail sheet on the same config skips the read', (
    tester,
  ) async {
    final config = await writeAppliedConfig(tester);
    globalState.lastConfigMd5 = 'applied';
    addTearDown(() => globalState.lastConfigMd5 = null);
    setUpProfiles([_profile(1)], session: _session(total: 0, used: 0));
    container.listen(groupsProvider, (_, _) {});
    await pumpCard(tester);

    await openRuntimeDetailFromAccount(tester);
    config.deleteSync();
    container.read(groupsProvider.notifier).value = [
      const Group(type: GroupType.Selector, name: 'G1'),
    ];
    await tester.pumpAndSettle();
    globalState.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    globalState.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    await openRuntimeDetailFromAccount(tester);

    expect(
      find.descendant(
        of: find.byType(ProfileDetailSheet),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('counts recorded at the last apply skip the config file', (
    tester,
  ) async {
    final config = await writeAppliedConfig(tester);
    await tester.runAsync(
      () => config.writeAsBytes(List.filled((8 << 20) + 1, 0x20)),
    );
    setUpProfiles([_profile(1)]);
    await pumpDesktopCard(tester);
    expect(find.byType(SkeletonText), findsNothing);
    expect(find.text('—'), findsNWidgets(3));

    globalState.lastConfigCounts = (groups: 4, proxies: 2048, rules: 9);
    addTearDown(() => globalState.lastConfigCounts = null);
    container.read(groupsProvider.notifier).value = [
      const Group(type: GroupType.Selector, name: 'G1'),
    ];
    await tester.pump();

    expect(find.text(dashboardCount(2048)), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.byType(SkeletonText), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card without a quota counts what its config holds', (
    tester,
  ) async {
    await writeAppliedConfig(tester);
    setUpProfiles(
      [_profile(1)],
      overrides: [
        providersProvider.overrideWithBuild(
          (_, _) => [_provider('nodes', 'Proxy', 5)],
        ),
      ],
    );
    await pumpDesktopCard(tester);
    await settleCounts(tester, until: find.text('3'));

    for (final (title, value) in [
      ('Proxy group', '1'),
      ('Proxies', '7'),
      ('Rules', '3'),
    ]) {
      expect(
        find.descendant(
          of: find
              .ancestor(of: find.text(title), matching: find.byType(Column))
              .first,
          matching: find.text(value),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a narrow card drops words before it cuts the time or traffic', (
    tester,
  ) async {
    final expiry = DateTime.now().add(const Duration(days: 30, hours: 1));
    setUpProfiles([
      _profile(
        1,
        type: ProfileType.url,
        info: SubscriptionInfo(
          upload: _gib,
          download: 41 * _gib,
          total: 100 * _gib,
          expire: expiry.millisecondsSinceEpoch ~/ 1000,
        ),
      ),
    ]);
    await pumpCard(
      tester,
      card: const DashboardDensityScope(
        density: DashboardDensity.standard,
        scale: 1,
        child: SizedBox(height: 176, child: ProfilesCard()),
      ),
      width: 600,
    );
    expect(find.textContaining('Updated'), findsOneWidget);
    expect(find.textContaining('used', findRichText: true), findsOneWidget);

    await pumpCard(
      tester,
      card: const DashboardDensityScope(
        density: DashboardDensity.standard,
        scale: 1,
        child: SizedBox(height: 176, child: ProfilesCard()),
      ),
      width: 240,
    );
    expect(find.textContaining('Updated'), findsNothing);
    expect(find.textContaining('minutes ago'), findsOneWidget);
    expect(find.textContaining('used', findRichText: true), findsNothing);
    expect(find.text('42 GB / 100 GB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a compact card puts the days left beside the name without switch button',
    (tester) async {
      final expiry = DateTime.now().add(const Duration(days: 30, hours: 1));
      setUpProfiles([
        _profile(
          1,
          type: ProfileType.url,
          info: SubscriptionInfo(
            upload: _gib,
            download: 41 * _gib,
            total: 100 * _gib,
            expire: expiry.millisecondsSinceEpoch ~/ 1000,
          ),
        ),
      ]);
      await pumpCard(
        tester,
        card: const DashboardDensityScope(
          density: DashboardDensity.compact,
          scale: 1,
          child: SizedBox(height: 152, child: ProfilesCard()),
        ),
        width: 220,
      );

      final name = tester.getRect(label('P1'));
      final daysLeft = tester.getRect(find.text('30 days left'));
      expect(daysLeft.center.dy, moreOrLessEquals(name.center.dy, epsilon: 1));
      expect(find.byTooltip('Switch profile'), findsNothing);
      expect(find.text('42 GB / 100 GB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'detail sheet hides runtime YAML preview unless developerMode is enabled',
    (tester) async {
      await writeAppliedConfig(tester);
      setUpProfiles(
        [_profile(1)],
        session: _session(total: 0, used: 0),
        overrides: [
          providersProvider.overrideWithBuild(
            (_, _) => [_provider('nodes', 'Proxy', 5)],
          ),
        ],
      );
      await pumpCard(tester);

      await openRuntimeDetailFromAccount(tester);

      expect(find.byType(ProfileDetailSheet), findsOneWidget);
      expect(find.byTooltip('Runtime config'), findsNothing);

      container
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(developerMode: true));
      await tester.pump();
      expect(find.byTooltip('Runtime config'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ExternalProvidersSliver),
          matching: find.byType(ProviderItem),
        ),
        findsOneWidget,
      );
    },
  );

  test('counts provider proxies but not provider rules', () {
    final stats = profileStatsOf(
      configCountsOf({
        'proxies': [{}],
        'proxy-groups': [{}, {}],
        'rules': ['MATCH,DIRECT'],
      }),
      [_provider('nodes', 'Proxy', 4), _provider('ads', 'Rule', 900)],
    );

    expect(stats, (groups: 2, proxies: 5, rules: 1, providers: 2));
  });

  testWidgets(
    'surfaces upgrade notice warning icon on dashboard card and opens account sheet',
    (tester) async {
      final base = _session();
      final withNotice = base.copyWith(
        bootstrap: base.bootstrap!.copyWith(
          upgradeNotice: const YoukoMixUpgradeNotice(
            enabled: true,
            mode: 'scheduled',
            cutoverAt: 1795204020,
            title: '开启 X25519MLKEM768 更新通知',
            message: '系统即将全面开启 X25519MLKEM768 支持，请确保及时将客户端及本地配置更新至最新版本。',
          ),
        ),
      );
      setUpProfiles([_profile(1)], session: withNotice);
      await pumpDesktopCard(tester);
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('开启 X25519MLKEM768 更新通知'), findsOneWidget);

      await tester.tap(find.byTooltip('开启 X25519MLKEM768 更新通知'));
      await tester.pumpAndSettle();
      expect(find.byType(YoukoMixAccountSheet), findsOneWidget);
      expect(find.text('开启 X25519MLKEM768 更新通知'), findsOneWidget);
    },
  );

  testWidgets(
    'shows unread announcement red dot on dashboard card and clears when opened',
    (tester) async {
      final base = _session();
      final withUnread = base.copyWith(
        bootstrap: base.bootstrap!.copyWith(
          announcements: const [
            YoukoMixAnnouncement(id: 30, title: '最新通知', markdown: '请及时更新客户端配置'),
          ],
        ),
      );
      setUpProfiles([_profile(1)], session: withUnread);
      await pumpDesktopCard(tester);
      expect(
        find.byKey(const ValueKey('youkomix-unread-ann-dot')),
        findsOneWidget,
      );

      await tester.tap(
        find.byTooltip(AppLocalizations.current.youkomixAnnouncements),
      );
      await tester.pumpAndSettle();
      expect(find.byType(YoukoMixAnnouncementsSheet), findsOneWidget);

      globalState.navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('youkomix-unread-ann-dot')),
        findsNothing,
      );
    },
  );
}
