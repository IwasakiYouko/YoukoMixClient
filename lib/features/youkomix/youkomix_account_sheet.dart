import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/youkomix/youkomix_markdown.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showYoukoMixAccountSheet(
  BuildContext context, {
  VoidCallback? onShowRuntimeDetail,
}) {
  showSheet<void>(
    context: context,
    builder: (_) =>
        YoukoMixAccountSheet(onShowRuntimeDetail: onShowRuntimeDetail),
  );
}

void showYoukoMixAnnouncementsSheet(BuildContext context) {
  showSheet<void>(
    context: context,
    builder: (_) => const YoukoMixAnnouncementsSheet(),
  );
}

void showYoukoMixPinnedAnnouncementSheet(
  BuildContext context,
  YoukoMixAnnouncement announcement,
) {
  showSheet<void>(
    context: context,
    builder: (_) => YoukoMixPinnedAnnouncementSheet(announcement: announcement),
  );
}

String _formatSpeedLimitMbps(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}

class YoukoMixAccountSheet extends ConsumerWidget {
  final VoidCallback? onShowRuntimeDetail;

  const YoukoMixAccountSheet({super.key, this.onShowRuntimeDetail});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    if (ref.read(youkomixControllerProvider).isBusy) return;
    final notifier = ref.read(youkomixControllerProvider.notifier);
    final appLocalizations = context.appLocalizations;
    final confirmed = await dialogs.showMessage(
      context: context,
      title: appLocalizations.youkomixLogout,
      message: TextSpan(text: appLocalizations.youkomixLogoutConfirm),
      confirmText: appLocalizations.youkomixLogout,
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    await notifier.logout();
  }

  void _openPanel(YoukoMixState authState, WidgetRef ref) {
    final panelUrl = authState.bootstrap?.links.panelUrl ?? '';
    final target = panelUrl.isNotEmpty
        ? panelUrl
        : (authState.serverUrl.isNotEmpty ? '${authState.serverUrl}/user' : '');
    if (target.isNotEmpty) {
      unawaited(
        ref.read(youkomixControllerProvider.notifier).openExternalUrl(target),
      );
    }
  }

  Future<void> _triggerCheckUpdate(BuildContext context, WidgetRef ref) async {
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

  Future<void> _copyDiagnostics(BuildContext context, WidgetRef ref) async {
    final tunEnabled = ref.read(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    final systemProxyEnabled = ref.read(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final summary = ref
        .read(youkomixControllerProvider.notifier)
        .buildDiagnosticSummary(
          isTunEnabled: tunEnabled,
          isSystemProxyEnabled: systemProxyEnabled,
        );
    await Clipboard.setData(ClipboardData(text: summary));
    if (context.mounted) {
      dialogs.showBanner(
        context.appLocalizations.youkomixDiagnosticsCopied,
        level: BannerLevel.success,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(youkomixControllerProvider);
    final profile = ref.watch(currentProfileProvider);
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final bootstrap = authState.bootstrap;
    final user = bootstrap?.user ?? const YoukoMixUser();
    final traffic = bootstrap?.traffic ?? const YoukoMixTraffic();
    final subscription =
        bootstrap?.subscription ?? const YoukoMixSubscriptionState();
    final commerce = authState.commerce;
    final features = authState.features;
    final isCommerce = authState.isCommerceEnabled;
    final isExclusive = authState.isExclusiveActive;
    final channelLocked = authState.isSyncing || authState.isBusy;
    final exclusiveChannelTitle = subscription.exclusiveTitle.trim().isNotEmpty
        ? subscription.exclusiveTitle.trim()
        : appLocalizations.youkomixSubChannelExclusive;
    final upgradeNotice = bootstrap?.upgradeNotice;
    final announcements = bootstrap?.announcements ?? const [];
    final rawSubInfo = profile?.subscriptionInfo;
    final subscriptionInfo =
        rawSubInfo != null &&
            (!isCommerce || user.userClass <= 0) &&
            rawSubInfo.expire != 0
        ? SubscriptionInfo(
            upload: rawSubInfo.upload,
            download: rawSubInfo.download,
            total: rawSubInfo.total,
            expire: 0,
          )
        : rawSubInfo;
    final expireDate = user.classExpireDate;
    final expireLabel = user.isExpired
        ? appLocalizations.youkomixExpired
        : (expireDate != null
              ? expireDate.show
              : appLocalizations.youkomixNeverExpire);

    final deviceLimitReached =
        user.nodeIpLimit > 0 && user.onlineIpCount >= user.nodeIpLimit;
    final deviceLabel = user.nodeIpLimit > 0
        ? appLocalizations.youkomixDeviceCount(
            user.onlineIpCount,
            user.nodeIpLimit,
          )
        : '${user.onlineIpCount} (${appLocalizations.youkomixUnlimited})';
    final speedLimitLabel = user.nodeSpeedLimit > 0
        ? '${_formatSpeedLimitMbps(user.nodeSpeedLimit)} Mbps'
        : appLocalizations.youkomixUnlimited;

    final showQuotaAlert = isCommerce
        ? (authState.isPlanExpiredOrInactive ||
              authState.isQuotaExhausted ||
              authState.isQuotaOrExpiryWarning)
        : authState.isQuotaExhausted;
    final quotaIsError =
        isCommerce &&
        (authState.isPlanExpiredOrInactive || authState.isQuotaExhausted);
    final quotaTitle = isCommerce
        ? appLocalizations.youkomixQuotaAlertTitle
        : appLocalizations.youkomixQuotaNoticeTitle;
    final quotaDescription = isCommerce
        ? (authState.isPlanExpiredOrInactive
              ? appLocalizations.youkomixQuotaExpiredDesc
              : (authState.isQuotaExhausted
                    ? appLocalizations.youkomixQuotaExhaustedDesc
                    : appLocalizations.youkomixQuotaWarningDesc))
        : (commerce.freeResetDay > 0
              ? appLocalizations.youkomixFreeQuotaExhaustedResetDesc(
                  commerce.freeResetDay,
                )
              : appLocalizations.youkomixFreeQuotaExhaustedDesc);
    final shopUrl = commerce.shopUrl.isNotEmpty
        ? commerce.shopUrl
        : authState.resolvePanelSubpath('/user/product');
    final canRenewInShop =
        isCommerce && commerce.products && shopUrl.isNotEmpty;

    final Widget? checkinAction = !features.checkinEnabled
        ? null
        : (features.ableToCheckin
              ? FilledButton.icon(
                  key: const ValueKey('youkomix-checkin-button'),
                  onPressed: authState.isCheckingIn || authState.isBusy
                      ? null
                      : () => unawaited(
                          ref
                              .read(youkomixControllerProvider.notifier)
                              .checkin(),
                        ),
                  icon: authState.isCheckingIn
                      ? const ActivityIndicator(size: 14)
                      : const GlyphIcon(AppGlyphs.sparkle, fill: 1, size: 15),
                  label: Text(
                    authState.isCheckingIn
                        ? appLocalizations.youkomixCheckingIn
                        : appLocalizations.youkomixCheckin,
                  ),
                )
              : TonalButton(
                  key: const ValueKey('youkomix-checked-in-pill'),
                  glyph: AppGlyphs.check,
                  label: appLocalizations.youkomixCheckedIn,
                  onPressed: null,
                ));

    final Widget? priorityNotice = authState.isClientOutdated
        ? _ActionNoticeCard(
            title: appLocalizations.youkomixClientUpdateRequiredTitle,
            message: appLocalizations.youkomixClientUpdateRequiredDesc(
              authState.meta?.minClientVersion ?? '',
            ),
            enforced: true,
            actionGlyph: AppGlyphs.cloudDownload,
            actionLabel: appLocalizations.checkUpdate,
            onAction: () => unawaited(_triggerCheckUpdate(context, ref)),
          )
        : (upgradeNotice != null && upgradeNotice.shouldDisplay
              ? _UpgradeNoticeCard(
                  notice: upgradeNotice,
                  isSyncing: authState.isSyncing,
                  onSync: authState.isSyncing || authState.isBusy
                      ? null
                      : () {
                          unawaited(
                            ref
                                .read(youkomixControllerProvider.notifier)
                                .syncSubscription(showFeedback: true),
                          );
                        },
                )
              : (showQuotaAlert
                    ? _ActionNoticeCard(
                        title: quotaTitle,
                        message: quotaDescription,
                        enforced: quotaIsError,
                        actionGlyph: canRenewInShop
                            ? AppGlyphs.openExternal
                            : null,
                        actionLabel: canRenewInShop
                            ? appLocalizations.youkomixRenewPlan
                            : null,
                        onAction: canRenewInShop
                            ? () {
                                unawaited(
                                  ref
                                      .read(youkomixControllerProvider.notifier)
                                      .openExternalUrl(shopUrl),
                                );
                              }
                            : null,
                      )
                    : null));

    final supportItems = <Widget>[
      if (authState.serverUrl.isNotEmpty)
        ListItem(
          leading: const GlyphIcon(AppGlyphs.openExternal),
          title: Text(appLocalizations.youkomixOpenPanel),
          onTap: () => _openPanel(authState, ref),
        ),
      if (profile != null && onShowRuntimeDetail != null)
        ListItem(
          leading: const GlyphIcon(AppGlyphs.profiles),
          title: Text(appLocalizations.runtimeConfig),
          trailing: const GlyphIcon(AppGlyphs.chevronForward),
          onTap: onShowRuntimeDetail,
        ),
      if (authState.panelBaseUrl.isNotEmpty && authState.isTicketEnabled)
        ListItem(
          leading: const GlyphIcon(AppGlyphs.send),
          title: Text(appLocalizations.youkomixSubmitTicket),
          trailing: const GlyphIcon(AppGlyphs.openExternal),
          onTap: () {
            unawaited(
              ref
                  .read(youkomixControllerProvider.notifier)
                  .openPanelSubpath('/user/ticket'),
            );
          },
        ),
      ListItem(
        leading: const GlyphIcon(AppGlyphs.copy),
        title: Text(appLocalizations.youkomixCopyDiagnostics),
        onTap: () => unawaited(_copyDiagnostics(context, ref)),
      ),
    ];

    return Scaffold(
      title: appLocalizations.youkomixAccount,
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.sync,
          tooltip: appLocalizations.youkomixSyncNodes,
          isLoading: authState.isSyncing,
          onPressed: () {
            unawaited(
              ref
                  .read(youkomixControllerProvider.notifier)
                  .syncSubscription(showFeedback: true),
            );
          },
        ),
        if (authState.serverUrl.isNotEmpty)
          IconButtonData(
            glyph: AppGlyphs.openExternal,
            tooltip: appLocalizations.youkomixOpenPanel,
            onPressed: () => _openPanel(authState, ref),
          ),
      ],
      body: CustomScrollView(
        controller: sheetScrollController(context),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
              top: context.contentTopPadding,
              bottom: 24 + context.bottomInset,
            ),
            sliver: SliverList.list(
              children: [
                _AccountHeaderCard(
                  userName: user.userName.isNotEmpty
                      ? user.userName
                      : (user.email.isNotEmpty ? user.email : appName),
                  email: user.email,
                  levelLabel: user.userClass > 0
                      ? appLocalizations.youkomixLevelBadge(user.userClass)
                      : null,
                  modeLabel: isExclusive
                      ? appLocalizations.youkomixSubModeExclusive
                      : appLocalizations.youkomixSubModeStandard,
                  isExclusive: isExclusive,
                  trailingAction: checkinAction,
                ),
                ?priorityNotice,
                if (subscription.exclusiveEnabled)
                  generateSection(
                    title: appLocalizations.youkomixSubChannel,
                    items: [
                      ListItem(
                        leading: GlyphIcon(
                          AppGlyphs.verified,
                          fill: isExclusive ? 1 : 0,
                          color: isExclusive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          exclusiveChannelTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          appLocalizations.youkomixSubChannelExclusiveDesc,
                        ),
                        trailing: isExclusive
                            ? GlyphIcon(
                                AppGlyphs.check,
                                color: colorScheme.primary,
                              )
                            : null,
                        onTap: channelLocked
                            ? null
                            : () => unawaited(
                                ref
                                    .read(youkomixControllerProvider.notifier)
                                    .switchSubscriptionMode(
                                      YoukoMixSubPreference.exclusive,
                                    ),
                              ),
                      ),
                      ListItem(
                        leading: GlyphIcon(
                          AppGlyphs.vpn,
                          fill: !isExclusive ? 1 : 0,
                          color: !isExclusive
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          appLocalizations.youkomixSubChannelStandard,
                        ),
                        subtitle: Text(
                          appLocalizations.youkomixSubChannelStandardDesc,
                        ),
                        trailing: !isExclusive
                            ? GlyphIcon(
                                AppGlyphs.check,
                                color: colorScheme.primary,
                              )
                            : null,
                        onTap: channelLocked
                            ? null
                            : () => unawaited(
                                ref
                                    .read(youkomixControllerProvider.notifier)
                                    .switchSubscriptionMode(
                                      YoukoMixSubPreference.standard,
                                    ),
                              ),
                      ),
                    ],
                  ),
                generateSection(
                  title: appLocalizations.youkomixUsageAndSpecs,
                  items: [
                    if (subscriptionInfo != null && subscriptionInfo.total > 0)
                      ListItem(
                        title: SubscriptionInfoView(
                          subscriptionInfo: subscriptionInfo,
                        ),
                      ),
                    if (traffic.today > 0)
                      _SheetValueRow(
                        label: appLocalizations.youkomixTodayTraffic,
                        value: traffic.today.traffic.show,
                      ),
                    _SheetValueRow(
                      label: appLocalizations.youkomixOnlineDevices,
                      value: deviceLabel,
                      highlightError: deviceLimitReached,
                    ),
                    _SheetValueRow(
                      label: appLocalizations.youkomixSpeedLimit,
                      value: speedLimitLabel,
                    ),
                    if (isCommerce && (user.userClass > 0 || user.isExpired))
                      _SheetValueRow(
                        label: appLocalizations.expireTime,
                        value: expireLabel,
                        highlightError: user.isExpired,
                      ),
                    if (isCommerce && commerce.balance)
                      _SheetValueRow(
                        label: appLocalizations.youkomixBalance,
                        value: '¥${user.money}',
                      ),
                    if (profile?.lastUpdateDate != null)
                      ListItem(
                        title: Text(appLocalizations.lastUpdated),
                        trailing: DefaultTextStyle.merge(
                          style: AppTextStyle.subheadline
                              .of(context)
                              .copyWith(color: colorScheme.onSurfaceVariant),
                          child: LastUpdateTimeText(
                            lastUpdateDate: profile!.lastUpdateDate,
                          ),
                        ),
                      ),
                  ],
                ),
                generateSection(
                  title: appLocalizations.youkomixAnnouncements,
                  items: [
                    ListItem(
                      leading: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const GlyphIcon(AppGlyphs.info),
                          if (authState.hasUnreadAnnouncements)
                            PositionedDirectional(
                              top: -2,
                              end: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: ShapeDecoration(
                                  color: colorScheme.error,
                                  shape: AppShape.full,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        announcements.isNotEmpty
                            ? announcements.first.title
                            : appLocalizations.youkomixNoAnnouncements,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: announcements.isNotEmpty
                          ? Text(
                              announcements.first.displayBody,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: const GlyphIcon(AppGlyphs.chevronForward),
                      onTap: () => showYoukoMixAnnouncementsSheet(context),
                    ),
                  ],
                ),
                generateSection(
                  title: appLocalizations.youkomixSupportAndPanel,
                  items: supportItems,
                ),
                if (authState.isAuthenticated)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: IgnorePointer(
                      ignoring: authState.isBusy,
                      child: TonalButton(
                        glyph: AppGlyphs.lock,
                        label: appLocalizations.youkomixLogout,
                        onPressed: () => _confirmLogout(context, ref),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class YoukoMixAnnouncementsSheet extends ConsumerStatefulWidget {
  const YoukoMixAnnouncementsSheet({super.key});

  @override
  ConsumerState<YoukoMixAnnouncementsSheet> createState() =>
      _YoukoMixAnnouncementsSheetState();
}

class _YoukoMixAnnouncementsSheetState
    extends ConsumerState<YoukoMixAnnouncementsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(youkomixControllerProvider.notifier).markAnnouncementsRead(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final announcements =
        ref.watch(youkomixControllerProvider).bootstrap?.announcements ??
        const <YoukoMixAnnouncement>[];
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;

    return Scaffold(
      title: appLocalizations.youkomixAnnouncements,
      body: announcements.isEmpty
          ? Center(
              child: NullStatus(
                label: appLocalizations.youkomixNoAnnouncements,
                illustration: NullStatusIllustration.data,
              ),
            )
          : CustomScrollView(
              controller: sheetScrollController(context),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
                    top: context.contentTopPadding + 8,
                    bottom: 24 + context.bottomInset,
                  ),
                  sliver: SliverList.list(
                    children: [
                      for (final item in announcements)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: ShapeDecoration(
                              color: context.raisedSurfaceLevel.colorOf(
                                colorScheme,
                              ),
                              shape: AppShape.all(AppCorner.lg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 10,
                              children: [
                                Row(
                                  spacing: 8,
                                  children: [
                                    if (item.isPinned)
                                      GlyphIcon(
                                        AppGlyphs.pin,
                                        fill: 1,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: AppTextStyle.headline
                                            .of(context, emphasized: true)
                                            .copyWith(
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.date.isNotEmpty)
                                  Text(
                                    item.date,
                                    style: AppTextStyle.caption1
                                        .of(context)
                                        .copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                YoukoMixMarkdownBody(
                                  source: item.richMarkdownSource,
                                  onTapLink: (url) {
                                    unawaited(
                                      ref
                                          .read(
                                            youkomixControllerProvider.notifier,
                                          )
                                          .openExternalUrl(url),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class YoukoMixPinnedAnnouncementSheet extends ConsumerWidget {
  final YoukoMixAnnouncement announcement;

  const YoukoMixPinnedAnnouncementSheet({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    return Scaffold(
      title: announcement.title.isNotEmpty
          ? announcement.title
          : appLocalizations.youkomixAnnouncements,
      body: CustomScrollView(
        controller: sheetScrollController(context),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
              top: context.contentTopPadding + 8,
              bottom: 24 + context.bottomInset,
            ),
            sliver: SliverList.list(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: ShapeDecoration(
                    color: context.raisedSurfaceLevel.colorOf(colorScheme),
                    shape: AppShape.all(AppCorner.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      if (announcement.date.isNotEmpty)
                        Text(
                          announcement.date,
                          style: AppTextStyle.caption1
                              .of(context)
                              .copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      YoukoMixMarkdownBody(
                        source: announcement.richMarkdownSource,
                        onTapLink: (url) {
                          unawaited(
                            ref
                                .read(youkomixControllerProvider.notifier)
                                .openExternalUrl(url),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      onPressed: () {
                        unawaited(
                          ref
                              .read(youkomixControllerProvider.notifier)
                              .acknowledgePinnedAnnouncement(announcement.id),
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const GlyphIcon(AppGlyphs.check, fill: 1, size: 16),
                      label: Text(appLocalizations.youkomixGotIt),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeaderCard extends StatelessWidget {
  final String userName;
  final String email;
  final String? levelLabel;
  final String modeLabel;
  final bool isExclusive;
  final Widget? trailingAction;

  const _AccountHeaderCard({
    required this.userName,
    required this.email,
    this.levelLabel,
    required this.modeLabel,
    required this.isExclusive,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: context.raisedSurfaceLevel.colorOf(colorScheme),
          shape: AppShape.all(AppCorner.lg),
        ),
        child: Row(
          spacing: 14,
          children: [
            ClipRSuperellipse(
              borderRadius: BorderRadius.circular(AppCorner.md),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFFEFEFE)),
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Flexible(
                        child: Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.title3
                              .of(context, emphasized: true)
                              .copyWith(color: colorScheme.onSurface),
                        ),
                      ),
                      if (levelLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: ShapeDecoration(
                            color: colorScheme.primaryContainer,
                            shape: AppShape.full,
                          ),
                          child: Text(
                            levelLabel!,
                            style: AppTextStyle.caption1
                                .of(context, emphasized: true)
                                .copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                    ],
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.footnote
                          .of(context)
                          .copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  Row(
                    spacing: 6,
                    children: [
                      GlyphIcon(
                        isExclusive ? AppGlyphs.verified : AppGlyphs.vpn,
                        fill: 1,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      Flexible(
                        child: Text(
                          modeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.caption1
                              .of(context)
                              .copyWith(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ?trailingAction,
          ],
        ),
      ),
    );
  }
}

class _UpgradeNoticeCard extends StatelessWidget {
  final YoukoMixUpgradeNotice notice;
  final bool isSyncing;
  final VoidCallback? onSync;

  const _UpgradeNoticeCard({
    required this.notice,
    required this.isSyncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return _ActionNoticeCard(
      title: notice.title.isNotEmpty ? notice.title : appLocalizations.tip,
      message: notice.message,
      enforced: notice.isEnforced,
      actionGlyph: AppGlyphs.sync,
      actionLabel: appLocalizations.sync,
      onAction: isSyncing ? null : onSync,
    );
  }
}

class _ActionNoticeCard extends StatelessWidget {
  final String title;
  final String message;
  final bool enforced;
  final Glyph? actionGlyph;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _ActionNoticeCard({
    required this.title,
    required this.message,
    required this.enforced,
    this.actionGlyph,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final containerColor = enforced
        ? colorScheme.errorContainer
        : colorScheme.warningContainer;
    final contentColor = enforced
        ? colorScheme.onErrorContainer
        : colorScheme.onWarningContainer;
    final accentColor = enforced ? colorScheme.error : colorScheme.warning;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: containerColor,
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
                  color: accentColor,
                ),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyle.headline
                        .of(context, emphasized: true)
                        .copyWith(color: contentColor),
                  ),
                ),
              ],
            ),
            if (message.isNotEmpty)
              Text(
                message,
                style: AppTextStyle.subheadline
                    .of(context)
                    .copyWith(color: contentColor),
              ),
            if (actionLabel != null && actionGlyph != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: onAction,
                  style: enforced
                      ? ButtonStyle.from(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        )
                      : null,
                  icon: GlyphIcon(actionGlyph!, fill: 1, size: 16),
                  label: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlightError;

  const _SheetValueRow({
    required this.label,
    required this.value,
    this.highlightError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return ListItem(
      title: Text(label),
      trailing: Text(
        value,
        style: AppTextStyle.subheadline
            .of(context)
            .copyWith(
              color: highlightError
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
