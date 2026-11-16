import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(youkomixControllerProvider);
    final profile = ref.watch(currentProfileProvider);
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final bootstrap = authState.bootstrap;
    final user = bootstrap?.user ?? const YoukoMixUser();
    final subscription =
        bootstrap?.subscription ?? const YoukoMixSubscriptionState();
    final announcements = bootstrap?.announcements ?? const [];
    final subscriptionInfo = profile?.subscriptionInfo;
    final expireDate = user.classExpireDate;
    final expireLabel = user.isExpired
        ? appLocalizations.youkomixExpired
        : (expireDate != null
              ? expireDate.show
              : appLocalizations.youkomixNeverExpire);

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
        IconButtonData(
          glyph: AppGlyphs.info,
          tooltip: appLocalizations.youkomixAnnouncements,
          onPressed: () => showYoukoMixAnnouncementsSheet(context),
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
                  levelLabel: appLocalizations.youkomixLevelBadge(
                    user.userClass,
                  ),
                  modeLabel: subscription.isExclusive
                      ? appLocalizations.youkomixSubModeExclusive
                      : appLocalizations.youkomixSubModeStandard,
                  isExclusive: subscription.isExclusive,
                ),
                if (subscriptionInfo != null && subscriptionInfo.total > 0)
                  generateSection(
                    title: appLocalizations.subscriptionInfo,
                    items: [
                      ListItem(
                        title: SubscriptionInfoView(
                          subscriptionInfo: subscriptionInfo,
                        ),
                      ),
                    ],
                  ),
                generateSection(
                  title: appLocalizations.youkomixAccount,
                  items: [
                    _SheetValueRow(
                      label: appLocalizations.expireTime,
                      value: expireLabel,
                      highlightError: user.isExpired,
                    ),
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
                      leading: const GlyphIcon(AppGlyphs.info),
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
                    if (profile != null && onShowRuntimeDetail != null)
                      ListItem(
                        leading: const GlyphIcon(AppGlyphs.profiles),
                        title: Text(appLocalizations.runtimeConfig),
                        trailing: const GlyphIcon(AppGlyphs.chevronForward),
                        onTap: onShowRuntimeDetail,
                      ),
                    if (authState.serverUrl.isNotEmpty)
                      ListItem(
                        leading: const GlyphIcon(AppGlyphs.openExternal),
                        title: Text(appLocalizations.youkomixOpenPanel),
                        onTap: () => _openPanel(authState, ref),
                      ),
                  ],
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

class YoukoMixAnnouncementsSheet extends ConsumerWidget {
  const YoukoMixAnnouncementsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                              spacing: 8,
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
                                SelectableText(
                                  item.displayBody,
                                  style: AppTextStyle.subheadline
                                      .of(context)
                                      .copyWith(color: colorScheme.onSurface),
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

class _AccountHeaderCard extends StatelessWidget {
  final String userName;
  final String email;
  final String levelLabel;
  final String modeLabel;
  final bool isExclusive;

  const _AccountHeaderCard({
    required this.userName,
    required this.email,
    required this.levelLabel,
    required this.modeLabel,
    required this.isExclusive,
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
                          levelLabel,
                          style: AppTextStyle.caption1
                              .of(context, emphasized: true)
                              .copyWith(color: colorScheme.onPrimaryContainer),
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
