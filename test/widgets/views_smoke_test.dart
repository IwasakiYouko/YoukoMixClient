import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/advanced.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/filters.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/ntp.dart';
import 'package:fl_clash/views/config/on_demand.dart';
import 'package:fl_clash/views/config/rules.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:fl_clash/views/config/sniffer.dart';
import 'package:fl_clash/views/config/tun.dart';
import 'package:fl_clash/views/config/user_agents.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/views/proxies/list.dart';
import 'package:fl_clash/views/proxies/tab.dart';
import 'package:fl_clash/views/theme.dart';
import 'package:fl_clash/views/views.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_database_providers.dart';
import '../helpers/test_profiles.dart';
import '../helpers/host_scaffold.dart';
import 'package:prism_ui/prism_ui.dart';

Finder _portField(String label) => find.descendant(
  of: find.widgetWithText(FormRow, label),
  matching: find.byType(TextFormField),
);

void main() {
  final cases = <String, Widget>{
    'dashboard': const DashboardView(),
    'proxies': const ProxiesView(),
    'requests': const RequestsView(initialFeed: RequestFeed.recent),
    'dns queries': const DnsQueriesView(),
    'resources': const ResourcesView(),
    'logs': const LogsView(),
    'tools': const ToolsView(),
    'general settings': const GeneralView(),
    'dns config': const DnsView(),
    'ntp config': NtpView(1),
    'sniffer config': SnifferView(1),
    'tun config': TunView(1),
    'network config': const HostScaffold(body: NetworkListView()),
    'advanced config': const AdvancedConfigView(),
    'on demand config': const OnDemandView(),
    'theme': const ThemeView(),
    'backup and restore': const BackupAndRestore(),
    'hotkeys': const HotKeyView(),
    'access control': const AccessView(),
    'added rules': const AddedRulesView(),
    'scripts': const ScriptsView(),
    'user agents': const UserAgentsView(),
    'filters': const FiltersView(),
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key} renders its default state', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          profilesProvider.overrideWith(TestProfiles.new),
          scriptsProvider.overrideWith(TestScripts.new),
          globalRulesProvider.overrideWith(TestGlobalRules.new),
          iconSetsProvider.overrideWith(TestIconSets.new),
          clashProvidersProvider.overrideWith(TestClashProviders.new),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TestApp(child: entry.value),
        ),
      );
      await tester.pump();
      if (entry.key == 'access control') {
        await tester.pump(const Duration(milliseconds: 301));
      }
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        for (var index = 0; index < 8; index++) {
          await tester.drag(scrollables.first, const Offset(0, -700));
          await tester.pump();
        }
      }

      expect(find.byWidget(entry.value), findsOneWidget);
      expect(tester.takeException(), null);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  final toolDestinations = <String, Type>{
    'Theme': ThemeView,
    'General': GeneralView,
    'Advanced configuration': AdvancedConfigView,
  };

  testWidgets('tools hides backup unless developerMode is enabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1400, 1000));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ToolsView()),
      ),
    );
    await tester.pump();
    expect(find.text('Backup and restore'), findsNothing);

    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(developerMode: true));
    await tester.pump();

    final target = find.text('Backup and restore');
    await tester.scrollUntilVisible(
      target,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(find.byType(BackupAndRestore), findsOneWidget);
  });

  for (final entry in toolDestinations.entries) {
    testWidgets('tools opens ${entry.key}', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [profilesProvider.overrideWith(TestProfiles.new)],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container
          .read(viewSizeProvider.notifier)
          .update((_) => const Size(1400, 1000));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(child: ToolsView()),
        ),
      );
      await tester.pump();

      final target = find.text(entry.key);
      await tester.scrollUntilVisible(
        target,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(find.byType(entry.value), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }

  testWidgets('custom resources list directly in advanced config', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1400, 1000));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ToolsView()),
      ),
    );
    await tester.pump();

    final advanced = find.text('Advanced configuration');
    await tester.scrollUntilVisible(
      advanced,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(advanced);
    await tester.pumpAndSettle();

    expect(find.text('Custom'), findsOneWidget);

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.byType(FiltersView), findsOneWidget);
    expect(tester.takeException(), null);
  });

  testWidgets('user agent item opens the page that applies a preset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1000, 800));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TestApp(
          child: HostScaffold(body: ListView(children: const [UaItem()])),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('User-Agent'));
    await tester.pumpAndSettle();
    expect(find.byType(UserAgentsView), findsOneWidget);
    expect(find.text('clash-verge/v2.4.2'), findsOneWidget);

    await tester.tap(find.text('clash-verge/v2.4.2'));
    await tester.pumpAndSettle();

    expect(
      container.read(patchClashConfigProvider).globalUa,
      'clash-verge/v2.4.2',
    );
    expect(tester.takeException(), null);
  });

  testWidgets('the port form refuses an emptied port', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1000, 800));
    final before = container.read(patchClashConfigProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: HostScaffold(body: PortItem())),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Port').first);
    await tester.pumpAndSettle();

    await tester.enterText(_portField('SOCKS port'), '');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), null);
    expect(container.read(patchClashConfigProvider), before);
    expect(_portField('SOCKS port'), findsOneWidget);
    expect(find.text('SOCKS port cannot be empty'), findsOneWidget);
  });

  testWidgets('proxies renders populated tab and list layouts', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profile = Profile.normal().copyWith(
      currentGroupName: 'Selector',
      selectedMap: {'Selector': 'Proxy 1'},
      unfoldSet: {'Selector'},
    );
    final proxies = List.generate(
      24,
      (index) => Proxy(name: 'Proxy $index', type: 'Direct'),
    );
    final group = Group(
      name: 'Selector',
      type: GroupType.Selector,
      hidden: false,
      now: 'Proxy 1',
      all: proxies,
    );
    final container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles([profile])),
        currentProfileIdProvider.overrideWithBuild((_, _) => profile.id),
        currentGroupsStateProvider.overrideWithValue(
          GroupsState(value: [group]),
        ),
        groupsProvider.overrideWithValue([group]),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1400, 1000));
    container.listen(proxiesStyleSettingProvider, (_, _) {});
    container
        .read(proxiesStyleSettingProvider.notifier)
        .update((state) => state.copyWith(type: ProxiesType.tab));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ProxiesView()),
      ),
    );
    await tester.pump();

    expect(container.read(proxiesTabStateProvider).groups, [group]);
    expect(find.byType(ProxiesTabView), findsOneWidget);
    expect(find.byType(ProxyGroupView), findsOneWidget);

    container
        .read(proxiesStyleSettingProvider.notifier)
        .update((state) => state.copyWith(type: ProxiesType.list));
    await tester.pump();
    expect(find.byType(ProxiesListView), findsOneWidget);

    final scrollables = find.byType(Scrollable);
    for (var index = 0; index < 8; index++) {
      await tester.drag(
        scrollables.last,
        const Offset(0, -700),
        warnIfMissed: false,
      );
      await tester.pump();
    }
    expect(tester.takeException(), null);
  });
}
