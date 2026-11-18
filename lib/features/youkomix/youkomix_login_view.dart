import 'dart:async';
import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class YoukoMixLoginView extends ConsumerStatefulWidget {
  const YoukoMixLoginView({super.key});

  @override
  ConsumerState<YoukoMixLoginView> createState() => _YoukoMixLoginViewState();
}

class _YoukoMixLoginViewState extends ConsumerState<YoukoMixLoginView>
    with WidgetsBindingObserver {
  static const _fieldScrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 140);

  final _serverController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _mfaController = TextEditingController();
  final _authCodeController = TextEditingController();

  bool _awaitingWebAuth = false;
  String? _detectedClipboardAuth;

  bool get _hasFixedServer => defaultYoukoMixServerUrl.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialServer = ref.read(youkomixControllerProvider).serverUrl;
    _serverController.text = initialServer;
    if (initialServer.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            ref
                .read(youkomixControllerProvider.notifier)
                .loadMeta(initialServer),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _mfaController.dispose();
    _authCodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingWebAuth) {
      unawaited(_inspectClipboardForAuthCode());
    }
  }

  Future<void> _inspectClipboardForAuthCode() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final detected = extractYoukoMixOneTimeCode(data?.text);
      if (!mounted) {
        return;
      }
      if (detected != _detectedClipboardAuth) {
        setState(() => _detectedClipboardAuth = detected);
      }
    } catch (_) {}
  }

  String _effectiveServerUrl() {
    if (_hasFixedServer) {
      return defaultYoukoMixServerUrl.trim();
    }
    return _serverController.text.trim();
  }

  Future<void> _submitLogin() async {
    final current = ref.read(youkomixControllerProvider);
    if (current.isBusy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final notifier = ref.read(youkomixControllerProvider.notifier);
    await notifier.login(
      serverUrl: _effectiveServerUrl(),
      email: _emailController.text,
      password: _passwordController.text,
      captchaCode: current.shouldShowCaptcha ? _captchaController.text : null,
    );
  }

  Future<void> _refreshCaptcha() async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    _captchaController.clear();
    await ref
        .read(youkomixControllerProvider.notifier)
        .refreshCaptcha(_effectiveServerUrl());
  }

  Future<void> _submitMfa() async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(youkomixControllerProvider.notifier)
        .verifyMfa(_mfaController.text);
  }

  Future<void> _handleWebAuth() async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    setState(() => _awaitingWebAuth = true);
    unawaited(_inspectClipboardForAuthCode());
    await ref
        .read(youkomixControllerProvider.notifier)
        .openWebAuth(_effectiveServerUrl());
  }

  Future<void> _submitRawAuthToken(String raw) async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final notifier = ref.read(youkomixControllerProvider.notifier);
    final deepLink = parseYoukoMixDeepLink(trimmed);
    if (deepLink is YoukoMixAuthDeepLink) {
      if (deepLink.serverUrl != null && !_hasFixedServer) {
        _serverController.text = deepLink.serverUrl!;
      }
      await notifier.handleDeepLink(deepLink);
      return;
    }
    await notifier.exchangeCode(
      code: trimmed,
      serverUrl: _effectiveServerUrl(),
    );
  }

  Future<void> _promptAuthCode() async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    final appLocalizations = context.appLocalizations;
    final rawInput = await dialogs.showCommonDialog<String>(
      context: context,
      child: InputDialog(
        title: appLocalizations.youkomixEnterAuthCode,
        value: '',
        labelText: appLocalizations.youkomixAuthCode,
        hintText: appLocalizations.youkomixAuthCodeHint,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return appLocalizations.emptyTip(appLocalizations.youkomixAuthCode);
          }
          return null;
        },
      ),
    );
    final trimmed = rawInput?.trim();
    if (!mounted || trimmed == null || trimmed.isEmpty) {
      return;
    }
    await _submitRawAuthToken(trimmed);
  }

  Future<void> _scanAuthQr() async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    final scanned = await BaseNavigator.push<String>(context, const ScanPage());
    if (!mounted || scanned == null || scanned.trim().isEmpty) {
      return;
    }
    final parsed = parseYoukoMixDeepLink(scanned);
    if (parsed is YoukoMixAuthDeepLink &&
        parsed.serverUrl != null &&
        !_hasFixedServer) {
      _serverController.text = parsed.serverUrl!;
    }
    await ref
        .read(youkomixControllerProvider.notifier)
        .handleRawDeepLink(scanned);
  }

  Future<void> _openPanelPath(String pathSuffix, String? explicitUrl) async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    final notifier = ref.read(youkomixControllerProvider.notifier);
    if (explicitUrl != null && explicitUrl.trim().isNotEmpty) {
      await notifier.openExternalUrl(explicitUrl.trim());
      return;
    }
    try {
      final base = normalizeYoukoMixServerUrl(_effectiveServerUrl());
      await notifier.openExternalUrl('$base$pathSuffix');
    } on YoukoMixApiException catch (error) {
      notifier.setServerUrl(_effectiveServerUrl());
      dialogs.showBanner(error.message, level: BannerLevel.error);
    }
  }

  Future<void> _triggerCheckUpdate() async {
    if (ref.read(loadingProvider(LoadingTag.checkUpdate))) return;
    final commonAction = ref.read(commonActionProvider.notifier);
    final result = await globalState.loadingRun(
      () async => (release: await request.checkForUpdate()),
      title: context.appLocalizations.checkUpdate,
      tag: LoadingTag.checkUpdate,
    );
    if (result == null) return;
    unawaited(
      commonAction.checkUpdateResultHandle(data: result.release, isUser: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(youkomixControllerProvider);
    ref.listen<String>(youkomixControllerProvider.select((s) => s.serverUrl), (
      prev,
      next,
    ) {
      if (!_hasFixedServer &&
          next.isNotEmpty &&
          _serverController.text.trim() != next) {
        _serverController.text = next;
      }
    });
    ref.listen<String?>(
      youkomixControllerProvider.select((s) => s.captchaChallenge?.captchaId),
      (prev, next) {
        if (prev != null && next != prev) {
          _captchaController.clear();
        }
      },
    );
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    final padding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 80;
    final topPad = (keyboardOpen ? 12.0 : 24.0) + padding.top;
    final bottomPad = 24.0 + math.max(padding.bottom, viewInsets.bottom);

    return Surface(
      color: colorScheme.surface,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            final minHeight = math.max(
              0.0,
              viewportConstraints.maxHeight - topPad - bottomPad,
            );
            return SingleChildScrollView(
              controller: sheetScrollController(context),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                20 + padding.left,
                topPad,
                20 + padding.right,
                bottomPad,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: keyboardOpen ? 14 : 20,
                      children: [
                        _BrandHeader(
                          title: authState.meta?.appName.isNotEmpty == true
                              ? authState.meta!.appName
                              : appName,
                          subtitle: authState.isMfaStep
                              ? appLocalizations.youkomixMfaDesc
                              : appLocalizations.youkomixTagline,
                          compact: keyboardOpen,
                        ),
                        if (authState.isClientOutdated)
                          _ClientUpdateRequiredBanner(
                            minVersion: authState.meta?.minClientVersion ?? '',
                            onUpdate: () => unawaited(_triggerCheckUpdate()),
                          ),
                        if (authState.errorMessage != null &&
                            authState.errorMessage!.isNotEmpty)
                          _StatusBanner(message: authState.errorMessage!),
                        if (authState.isMfaStep)
                          _buildMfaStep(context, authState)
                        else
                          _buildPasswordStep(context, authState),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordStep(BuildContext context, YoukoMixState authState) {
    final appLocalizations = context.appLocalizations;
    final meta = authState.meta;
    final showCaptcha = authState.shouldShowCaptcha;
    return AutofillGroup(
      child: Column(
        key: const ValueKey('youkomix-password-step'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          generateGroup([
            if (!_hasFixedServer)
              FormRow(
                title: appLocalizations.youkomixServerUrl,
                trailing: FormRowTextField(
                  controller: _serverController,
                  hintText: appLocalizations.youkomixServerUrlHint,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  scrollPadding: _fieldScrollPadding,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    ref
                        .read(youkomixControllerProvider.notifier)
                        .setServerUrl(value);
                  },
                  onFieldSubmitted: (value) {
                    unawaited(
                      ref
                          .read(youkomixControllerProvider.notifier)
                          .loadMeta(value),
                    );
                  },
                ),
              ),
            FormRow(
              title: appLocalizations.youkomixEmail,
              trailing: FormRowTextField(
                controller: _emailController,
                hintText: appLocalizations.youkomixEmailHint,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                scrollPadding: _fieldScrollPadding,
                textInputAction: TextInputAction.next,
                onChanged: (_) =>
                    ref.read(youkomixControllerProvider.notifier).clearError(),
              ),
            ),
            FormRow(
              title: appLocalizations.password,
              trailing: FormRowSecretTextField(
                controller: _passwordController,
                hintText: appLocalizations.password,
                autofillHints: const [AutofillHints.password],
                scrollPadding: _fieldScrollPadding,
                textInputAction: showCaptcha
                    ? TextInputAction.next
                    : TextInputAction.done,
                onChanged: (_) =>
                    ref.read(youkomixControllerProvider.notifier).clearError(),
                onFieldSubmitted: showCaptcha
                    ? null
                    : (_) => unawaited(_submitLogin()),
              ),
            ),
          ]),
          if (showCaptcha)
            generateGroup([
              _CaptchaChallengeCard(
                challenge: authState.captchaChallenge,
                isLoading: authState.isLoadingCaptcha,
                onRefresh: _refreshCaptcha,
              ),
              FormRow(
                title: appLocalizations.youkomixCaptchaCode,
                trailing: FormRowTextField(
                  controller: _captchaController,
                  hintText: appLocalizations.youkomixCaptchaHint,
                  autocorrect: false,
                  scrollPadding: _fieldScrollPadding,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => ref
                      .read(youkomixControllerProvider.notifier)
                      .clearError(),
                  onFieldSubmitted: (_) => unawaited(_submitLogin()),
                ),
              ),
            ]),
          SizedBox(
            height: 46,
            child: IgnorePointer(
              ignoring: authState.isBusy,
              child: FilledButton.icon(
                onPressed: _submitLogin,
                icon: authState.isBusy
                    ? const ActivityIndicator(size: 16)
                    : const GlyphIcon(AppGlyphs.vpn, fill: 1),
                label: Text(
                  authState.isBusy
                      ? appLocalizations.youkomixLoggingIn
                      : appLocalizations.youkomixLogin,
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: authState.isBusy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                TonalButton(
                  glyph: AppGlyphs.openExternal,
                  label: appLocalizations.youkomixWebAuth,
                  onPressed: _handleWebAuth,
                ),
                if (_awaitingWebAuth)
                  _WebAuthWaitingCard(
                    controller: _authCodeController,
                    detectedClipboardCode: _detectedClipboardAuth,
                    onUseClipboardCode: _detectedClipboardAuth == null
                        ? null
                        : () => unawaited(
                            _submitRawAuthToken(_detectedClipboardAuth!),
                          ),
                    onSubmitManual: () => unawaited(
                      _submitRawAuthToken(_authCodeController.text),
                    ),
                    onScanQr: system.isDesktop ? null : _scanAuthQr,
                    onDismiss: () => setState(() => _awaitingWebAuth = false),
                  )
                else
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: TonalButton(
                          glyph: AppGlyphs.key,
                          label: appLocalizations.youkomixEnterAuthCode,
                          onPressed: _promptAuthCode,
                        ),
                      ),
                      if (!system.isDesktop)
                        Expanded(
                          child: TonalButton(
                            glyph: AppGlyphs.qrCode,
                            label: appLocalizations.youkomixScanAuthQr,
                            onPressed: _scanAuthQr,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          IgnorePointer(
            ignoring: authState.isBusy,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                if (authState.canRegister)
                  TextButton(
                    onPressed: () =>
                        _openPanelPath('/auth/register', meta?.registerUrl),
                    child: Text(appLocalizations.youkomixRegister),
                  ),
                TextButton(
                  onPressed: () =>
                      _openPanelPath('/password/reset', meta?.passwordResetUrl),
                  child: Text(appLocalizations.youkomixForgotPassword),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMfaStep(BuildContext context, YoukoMixState authState) {
    final appLocalizations = context.appLocalizations;
    return AutofillGroup(
      child: Column(
        key: const ValueKey('youkomix-mfa-step'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          generateGroup([
            FormRow(
              title: appLocalizations.youkomixMfaCode,
              trailing: FormRowTextField(
                controller: _mfaController,
                hintText: '000000',
                keyboardType: TextInputType.number,
                autocorrect: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                scrollPadding: _fieldScrollPadding,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textInputAction: TextInputAction.done,
                onChanged: (_) =>
                    ref.read(youkomixControllerProvider.notifier).clearError(),
                onFieldSubmitted: (_) => unawaited(_submitMfa()),
              ),
            ),
          ]),
          SizedBox(
            height: 46,
            child: IgnorePointer(
              ignoring: authState.isBusy,
              child: FilledButton.icon(
                onPressed: _submitMfa,
                icon: authState.isBusy
                    ? const ActivityIndicator(size: 16)
                    : const GlyphIcon(AppGlyphs.verified, fill: 1),
                label: Text(appLocalizations.youkomixVerify),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: authState.isBusy,
            child: TonalButton(
              glyph: AppGlyphs.arrowBack,
              label: appLocalizations.youkomixBackToLogin,
              onPressed: () {
                if (ref.read(youkomixControllerProvider).isBusy) return;
                _mfaController.clear();
                ref.read(youkomixControllerProvider.notifier).cancelMfa();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WebAuthWaitingCard extends StatelessWidget {
  final TextEditingController controller;
  final String? detectedClipboardCode;
  final VoidCallback? onUseClipboardCode;
  final VoidCallback onSubmitManual;
  final VoidCallback? onScanQr;
  final VoidCallback onDismiss;

  const _WebAuthWaitingCard({
    required this.controller,
    required this.detectedClipboardCode,
    required this.onUseClipboardCode,
    required this.onSubmitManual,
    required this.onScanQr,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    return Container(
      key: const ValueKey('youkomix-webauth-waiting-card'),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerLow,
        shape: AppShape.all(AppCorner.lg).copyWith(
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              GlyphIcon(
                AppGlyphs.openExternal,
                fill: 1,
                size: 16,
                color: colorScheme.primary,
              ),
              Expanded(
                child: Text(
                  appLocalizations.youkomixWebAuthWaitingTitle,
                  style: AppTextStyle.subheadline
                      .of(context, emphasized: true)
                      .copyWith(color: colorScheme.onSurface),
                ),
              ),
              if (onScanQr != null)
                IconButton(
                  tooltip: appLocalizations.youkomixScanAuthQr,
                  onPressed: onScanQr,
                  icon: GlyphIcon(
                    AppGlyphs.qrCode,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              IconButton(
                tooltip: appLocalizations.close,
                onPressed: onDismiss,
                icon: GlyphIcon(
                  AppGlyphs.close,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            appLocalizations.youkomixWebAuthWaitingDesc,
            style: AppTextStyle.footnote
                .of(context)
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
          if (detectedClipboardCode != null && onUseClipboardCode != null)
            FilledButton.icon(
              onPressed: onUseClipboardCode,
              icon: const GlyphIcon(AppGlyphs.check, fill: 1, size: 16),
              label: Text(appLocalizations.youkomixClipboardAuthDetected),
            ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: generateGroup([
                  FormRow(
                    title: appLocalizations.youkomixAuthCode,
                    trailing: FormRowTextField(
                      controller: controller,
                      hintText: appLocalizations.youkomixAuthCodeHint,
                      autocorrect: false,
                      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => onSubmitManual(),
                    ),
                  ),
                ]),
              ),
              IconButton(
                tooltip: appLocalizations.submit,
                onPressed: onSubmitManual,
                icon: GlyphIcon(
                  AppGlyphs.send,
                  fill: 1,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientUpdateRequiredBanner extends StatelessWidget {
  final String minVersion;
  final VoidCallback onUpdate;

  const _ClientUpdateRequiredBanner({
    required this.minVersion,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    return Container(
      key: const ValueKey('youkomix-min-version-banner'),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: colorScheme.errorContainer,
        shape: AppShape.all(AppCorner.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 8,
            children: [
              GlyphIcon(
                AppGlyphs.warning,
                fill: 1,
                size: 18,
                color: colorScheme.error,
              ),
              Expanded(
                child: Text(
                  appLocalizations.youkomixClientUpdateRequiredTitle,
                  style: AppTextStyle.subheadline
                      .of(context, emphasized: true)
                      .copyWith(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
          Text(
            appLocalizations.youkomixClientUpdateRequiredDesc(minVersion),
            style: AppTextStyle.footnote
                .of(context)
                .copyWith(color: colorScheme.onErrorContainer),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: onUpdate,
              style: ButtonStyle.from(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              icon: const GlyphIcon(AppGlyphs.cloudDownload, fill: 1, size: 16),
              label: Text(appLocalizations.checkUpdate),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptchaChallengeCard extends StatelessWidget {
  final YoukoMixCaptchaChallenge? challenge;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _CaptchaChallengeCard({
    required this.challenge,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    final hasImage = challenge != null && challenge!.imageBytes.isNotEmpty;

    return ListItem(
      key: const ValueKey('youkomix-captcha-card'),
      onTap: isLoading ? null : onRefresh,
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(AppCorner.md),
          child: Container(
            width: 140,
            height: 44,
            color: const Color(0xFFFDF4F7),
            alignment: Alignment.center,
            child: hasImage
                ? Image.memory(
                    challenge!.imageBytes,
                    width: 140,
                    height: 44,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  )
                : (isLoading
                      ? const ActivityIndicator(size: 16)
                      : GlyphIcon(
                          AppGlyphs.refresh,
                          size: 18,
                          color: colorScheme.primary,
                        )),
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (isLoading && hasImage)
            const ActivityIndicator(size: 14)
          else
            GlyphIcon(AppGlyphs.refresh, size: 16, color: colorScheme.primary),
          Text(
            appLocalizations.youkomixCaptchaRefresh,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.footnote
                .of(context)
                .copyWith(color: colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const _BrandHeader({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final logoDimension = compact ? 44.0 : 72.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: compact ? 6 : 10,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: ShapeDecoration(
            color: const Color(0xFFFEFEFE),
            shape: (compact ? AppShape.lg : AppShape.xl).copyWith(
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.24),
              ),
            ),
          ),
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(
              compact ? AppCorner.md : AppCorner.lg,
            ),
            child: Image.asset(
              'assets/images/icon.png',
              width: logoDimension,
              height: logoDimension,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: (compact ? AppTextStyle.title3 : AppTextStyle.title1)
              .of(context, emphasized: true)
              .copyWith(color: colorScheme.onSurface),
        ),
        if (!compact)
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyle.subheadline
                .of(context)
                .copyWith(color: colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;

  const _StatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: colorScheme.errorContainer,
        shape: AppShape.all(AppCorner.lg),
      ),
      child: Row(
        spacing: 10,
        children: [
          GlyphIcon(
            AppGlyphs.error,
            fill: 1,
            size: 18,
            color: colorScheme.onErrorContainer,
          ),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle.footnote
                  .of(context)
                  .copyWith(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
