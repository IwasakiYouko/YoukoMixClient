import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/features/youkomix/youkomix.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/home.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/dashboard.dart';
import 'package:fl_clash/views/navigation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:prism_ui/prism_ui.dart';

import '../helpers/host_scaffold.dart';
import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';
import '../helpers/youkomix_e2ee_server.dart';

class _MockApiClient extends Mock implements YoukoMixApiClient {}

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
  Future<void> purgeUnmanagedProfiles() async {
    final managed = ref
        .read(profilesProvider)
        .where((p) => p.id == youkomixManagedProfileId)
        .toList();
    ref.read(profilesProvider.notifier).reorder(managed);
  }

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
      lastUpdateDate: DateTime.now(),
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

  late _MockApiClient api;
  late _MemorySessionStorage storage;
  late List<String> launchedUrls;

  setUp(() {
    navigationPort = navigation;
    api = _MockApiClient();
    when(() => api.fetchMeta(any())).thenAnswer(
      (_) async => const YoukoMixMeta(
        appName: '人间之里',
        baseUrl: 'https://panel.example.com',
        captchaEnabled: true,
        webAuthUrl: 'https://panel.example.com/user/client-auth',
        registerUrl: 'https://panel.example.com/auth/register',
        passwordResetUrl: 'https://panel.example.com/password/reset',
      ),
    );
    storage = _MemorySessionStorage();
    launchedUrls = [];
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        youkomixGateEnabledProvider.overrideWithValue(true),
        youkomixInitialSessionProvider.overrideWithValue(null),
        youkomixApiProvider.overrideWithValue(api),
        youkomixStorageProvider.overrideWithValue(storage),
        youkomixUrlLauncherProvider.overrideWithValue((url) async {
          launchedUrls.add(url);
          return true;
        }),
        profilesProvider.overrideWith(TestProfiles.new),
        profilesActionProvider.overrideWith(_MemoryProfilesAction.new),
        setupActionProvider.overrideWith(_IdleSetupAction.new),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    container.read(viewSizeProvider.notifier).value = const Size(1200, 1000);
    return container;
  }

  Finder fieldFor(String title) => find.descendant(
    of: find.widgetWithText(FormRow, title),
    matching: find.byType(TextFormField),
  );

  testWidgets(
    'HomePage gates unauthenticated user onto YoukoMixLoginView and unlocks after MFA',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => api.login(
          serverUrl: 'https://panel.example.com',
          email: 'reimu@example.com',
          password: 'secret',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixLoginMfaRequired(
          challengeToken: 'mfa_tok_99',
          webAuthUrl: 'https://panel.example.com/user/client-auth',
        ),
      );
      when(
        () => api.verifyMfa(
          serverUrl: 'https://panel.example.com',
          challengeToken: 'mfa_tok_99',
          code: '654321',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixSession(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_authenticated',
          expiresAt: 1999999999,
          bootstrap: YoukoMixBootstrap(
            user: YoukoMixUser(id: 1, userName: '博丽灵梦', userClass: 2),
          ),
        ),
      );
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_authenticated',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer(
        (_) async => YoukoMixSubscriptionPayload(
          bytes: Uint8List.fromList(utf8.encode('proxies: []\n')),
          mode: 'exclusive',
          title: '人间之里',
        ),
      );

      final container = buildContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(child: HomePage()),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;

      expect(find.byType(YoukoMixLoginView), findsOneWidget);
      expect(find.byType(DashboardView), findsNothing);
      expect(find.text('人间之里'), findsOneWidget);

      await tester.enterText(
        fieldFor(l10n.youkomixServerUrl),
        'https://panel.example.com',
      );
      await tester.enterText(fieldFor(l10n.youkomixEmail), 'reimu@example.com');
      await tester.enterText(fieldFor(l10n.password), 'secret');
      await tester.tap(find.text(l10n.youkomixLogin));
      await tester.pumpAndSettle();

      expect(find.text(l10n.youkomixMfaCode), findsOneWidget);

      await tester.enterText(fieldFor(l10n.youkomixMfaCode), '654321');
      await tester.tap(find.text(l10n.youkomixVerify));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(YoukoMixLoginView), findsNothing);
      expect(find.byType(DashboardView), findsOneWidget);
      expect(storage.saved?.accessToken, 'ymx_authenticated');
    },
  );

  testWidgets(
    'supports browser web-auth, register/forgot links, and manual one-time code',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => api.exchangeCode(
          serverUrl: 'https://panel.example.com',
          code: 'ymxc_manual_1',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixSession(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_manual_tok',
          expiresAt: 1999999999,
        ),
      );
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_manual_tok',
        ),
      ).thenAnswer((_) async => const YoukoMixBootstrap());
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_manual_tok',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer(
        (_) async => YoukoMixSubscriptionPayload(
          bytes: Uint8List.fromList(utf8.encode('proxies: []\n')),
          mode: 'standard',
          title: '人间之里',
        ),
      );

      final container = buildContainer();
      storage.setActiveServerUrl('https://panel.example.com');
      container
          .read(youkomixControllerProvider.notifier)
          .setServerUrl('https://panel.example.com');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(child: HostScaffold(body: YoukoMixLoginView())),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;

      await tester.tap(find.text(l10n.youkomixRegister));
      await tester.pumpAndSettle();
      expect(launchedUrls.last, 'https://panel.example.com/auth/register');

      await tester.tap(find.text(l10n.youkomixForgotPassword));
      await tester.pumpAndSettle();
      expect(launchedUrls.last, 'https://panel.example.com/password/reset');

      await tester.tap(find.text(l10n.youkomixWebAuth));
      await tester.pumpAndSettle();
      expect(
        launchedUrls.last,
        startsWith('https://panel.example.com/user/client-auth'),
      );
      expect(
        find.byKey(const ValueKey('youkomix-webauth-waiting-card')),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('youkomix-webauth-waiting-card')),
          matching: find.byType(TextFormField),
        ),
        'ymxc_manual_1',
      );
      await tester.tap(find.byTooltip(l10n.submit));
      await tester.pumpAndSettle();

      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isTrue,
      );
      expect(storage.saved?.accessToken, 'ymx_manual_tok');
    },
  );

  testWidgets(
    'renders inline native PNG CAPTCHA, refreshes challenge on tap, and signs in without opening browser',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ch1 = YoukoMixCaptchaChallenge.fromJson(const {
        'captcha_id': 'cch_ui_1',
        'image_base64': tinyValidPngBase64,
        'expires_in': 180,
      });
      final ch2 = YoukoMixCaptchaChallenge.fromJson(const {
        'captcha_id': 'cch_ui_2',
        'image_base64': tinyValidPngBase64,
        'expires_in': 180,
      });
      var fetchCount = 0;
      when(() => api.fetchCaptcha('https://panel.example.com')).thenAnswer((
        _,
      ) async {
        fetchCount++;
        return fetchCount == 1 ? ch1 : ch2;
      });
      when(
        () => api.login(
          serverUrl: 'https://panel.example.com',
          email: 'reimu@example.com',
          password: 'secret',
          captchaId: 'cch_ui_2',
          captchaCode: 'K9P7W',
        ),
      ).thenAnswer(
        (_) async => const YoukoMixLoginAuthenticated(
          YoukoMixSession(
            serverUrl: 'https://panel.example.com',
            accessToken: 'ymx_captcha_ok',
            expiresAt: 1999999999,
          ),
        ),
      );
      when(
        () => api.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_captcha_ok',
        ),
      ).thenAnswer((_) async => const YoukoMixBootstrap());
      when(
        () => api.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_captcha_ok',
          userAgent: any(named: 'userAgent'),
        ),
      ).thenAnswer(
        (_) async => YoukoMixSubscriptionPayload(
          bytes: Uint8List.fromList(utf8.encode('proxies: []\n')),
          mode: 'standard',
          title: '人间之里',
        ),
      );

      final container = buildContainer();
      container
          .read(youkomixControllerProvider.notifier)
          .setServerUrl('https://panel.example.com');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(child: HostScaffold(body: YoukoMixLoginView())),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;

      expect(
        find.byKey(const ValueKey('youkomix-captcha-card')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('youkomix-captcha-card')));
      await tester.pumpAndSettle();
      expect(
        container.read(youkomixControllerProvider).captchaChallenge?.captchaId,
        'cch_ui_2',
      );

      await tester.enterText(fieldFor(l10n.youkomixEmail), 'reimu@example.com');
      await tester.enterText(fieldFor(l10n.password), 'secret');
      await tester.enterText(fieldFor(l10n.youkomixCaptchaCode), 'K9P7W');
      await tester.tap(find.text(l10n.youkomixLogin));
      await tester.pumpAndSettle();

      expect(launchedUrls, isEmpty);
      expect(
        container.read(youkomixControllerProvider).isAuthenticated,
        isTrue,
      );
      expect(storage.saved?.accessToken, 'ymx_captcha_ok');
    },
  );

  testWidgets(
    'places CAPTCHA image above input field, respects keyboard viewInsets, and shows WebAuth waiting card',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      final ch = YoukoMixCaptchaChallenge.fromJson(const {
        'captcha_id': 'cch_mobile_1',
        'image_base64': tinyValidPngBase64,
        'expires_in': 180,
      });
      when(
        () => api.fetchCaptcha('https://panel.example.com'),
      ).thenAnswer((_) async => ch);

      final container = ProviderContainer(
        overrides: [
          youkomixGateEnabledProvider.overrideWithValue(true),
          youkomixInitialSessionProvider.overrideWithValue(null),
          youkomixCurrentAppVersionProvider.overrideWithValue('1.0.0'),
          youkomixApiProvider.overrideWithValue(api),
          youkomixStorageProvider.overrideWithValue(storage),
          youkomixUrlLauncherProvider.overrideWithValue((url) async {
            launchedUrls.add(url);
            return true;
          }),
          profilesProvider.overrideWith(TestProfiles.new),
          profilesActionProvider.overrideWith(_MemoryProfilesAction.new),
          setupActionProvider.overrideWith(_IdleSetupAction.new),
        ],
      );
      addTearDown(container.dispose);
      globalState.container = container;
      container.read(viewSizeProvider.notifier).value = const Size(390, 844);

      when(() => api.fetchMeta('https://panel.example.com')).thenAnswer(
        (_) async => const YoukoMixMeta(
          appName: '人间之里',
          baseUrl: 'https://panel.example.com',
          captchaEnabled: true,
          minClientVersion: '1.2.0',
          regMode: 'close',
          webAuthUrl: 'https://panel.example.com/user/client-auth',
        ),
      );
      container
          .read(youkomixControllerProvider.notifier)
          .setServerUrl('https://panel.example.com');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const TestApp(child: HostScaffold(body: YoukoMixLoginView())),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;

      expect(
        find.byKey(const ValueKey('youkomix-min-version-banner')),
        findsOneWidget,
      );
      expect(find.text(l10n.youkomixCaptchaRequiredTip), findsNothing);
      expect(find.text(l10n.youkomixRegister), findsNothing);
      expect(find.text(l10n.youkomixForgotPassword), findsOneWidget);
      final captchaCardRect = tester.getRect(
        find.byKey(const ValueKey('youkomix-captcha-card')),
      );
      final captchaInputRect = tester.getRect(
        fieldFor(l10n.youkomixCaptchaCode),
      );
      expect(captchaCardRect.top, lessThan(captchaInputRect.top));
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text(l10n.youkomixWebAuth),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(l10n.youkomixWebAuth));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('youkomix-webauth-waiting-card')),
        findsOneWidget,
      );
    },
  );
}
