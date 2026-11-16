import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:fl_clash/pages/scan.dart';
import 'package:fl_clash/providers/youkomix.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism_ui/prism_ui.dart';

class YoukoMixLoginView extends ConsumerStatefulWidget {
  const YoukoMixLoginView({super.key});

  @override
  ConsumerState<YoukoMixLoginView> createState() => _YoukoMixLoginViewState();
}

class _YoukoMixLoginViewState extends ConsumerState<YoukoMixLoginView> {
  final _serverController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaController = TextEditingController();

  bool get _hasFixedServer => defaultYoukoMixServerUrl.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
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
    _serverController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mfaController.dispose();
    super.dispose();
  }

  String _effectiveServerUrl() {
    if (_hasFixedServer) {
      return defaultYoukoMixServerUrl.trim();
    }
    return _serverController.text.trim();
  }

  Future<void> _submitLogin() async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final notifier = ref.read(youkomixControllerProvider.notifier);
    await notifier.login(
      serverUrl: _effectiveServerUrl(),
      email: _emailController.text,
      password: _passwordController.text,
    );
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
    await ref
        .read(youkomixControllerProvider.notifier)
        .openWebAuth(_effectiveServerUrl());
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
    final colorScheme = context.colorScheme;
    final appLocalizations = context.appLocalizations;
    final padding = MediaQuery.paddingOf(context);

    return Surface(
      color: colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          controller: sheetScrollController(context),
          padding: EdgeInsets.fromLTRB(
            20 + padding.left,
            24 + padding.top,
            20 + padding.right,
            24 + padding.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                _BrandHeader(
                  title: authState.meta?.appName.isNotEmpty == true
                      ? authState.meta!.appName
                      : appName,
                  subtitle: authState.isMfaStep
                      ? appLocalizations.youkomixMfaDesc
                      : appLocalizations.youkomixTagline,
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
  }

  Widget _buildPasswordStep(BuildContext context, YoukoMixState authState) {
    final appLocalizations = context.appLocalizations;
    final meta = authState.meta;
    return Column(
      key: const ValueKey('youkomix-password-step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (meta?.captchaEnabled == true)
          _InfoBanner(message: appLocalizations.youkomixCaptchaRequiredTip),
        generateGroup([
          if (!_hasFixedServer)
            FormRow(
              title: appLocalizations.youkomixServerUrl,
              trailing: FormRowTextField(
                controller: _serverController,
                hintText: appLocalizations.youkomixServerUrlHint,
                keyboardType: TextInputType.url,
                autocorrect: false,
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
              textInputAction: TextInputAction.done,
              onChanged: (_) =>
                  ref.read(youkomixControllerProvider.notifier).clearError(),
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
    );
  }

  Widget _buildMfaStep(BuildContext context, YoukoMixState authState) {
    final appLocalizations = context.appLocalizations;
    return Column(
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
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BrandHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: ShapeDecoration(
            color: const Color(0xFFFEFEFE),
            shape: AppShape.xl.copyWith(
              side: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.24),
              ),
            ),
          ),
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(AppCorner.lg),
            child: Image.asset(
              'assets/images/icon.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyle.title1
              .of(context, emphasized: true)
              .copyWith(color: colorScheme.onSurface),
        ),
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

class _InfoBanner extends StatelessWidget {
  final String message;

  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: colorScheme.primaryContainer,
        shape: AppShape.all(AppCorner.lg),
      ),
      child: Row(
        spacing: 10,
        children: [
          GlyphIcon(
            AppGlyphs.info,
            fill: 1,
            size: 18,
            color: colorScheme.onPrimaryContainer,
          ),
          Expanded(
            child: Text(
              message,
              style: AppTextStyle.footnote
                  .of(context)
                  .copyWith(color: colorScheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
