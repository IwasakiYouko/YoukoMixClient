import 'dart:async';
import 'dart:math' as math;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/features/youkomix/youkomix.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/views/dashboard/layout.dart';
import 'package:fl_clash/views/dashboard/style.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism_ui/prism_ui.dart';

import 'card.dart';
import 'profile_detail.dart';

typedef _Usage = ({int used, int total, double share});

_Usage? _usageOf(YoukoMixTraffic? traffic, Profile? profile) {
  if (traffic != null && traffic.total > 0) {
    final used = traffic.used;
    return (
      used: used,
      total: traffic.total,
      share: (used / traffic.total).clamp(0.0, 1.0).toDouble(),
    );
  }
  final info = profile?.subscriptionInfo;
  if (info == null || info.total <= 0) {
    return null;
  }
  final used = info.upload + info.download;
  return (
    used: used,
    total: info.total,
    share: (used / info.total).clamp(0.0, 1.0).toDouble(),
  );
}

DateTime? _expiryOf(Profile? profile) {
  final expire = profile?.subscriptionInfo?.expire ?? 0;
  return expire > 0 ? DateTime.fromMillisecondsSinceEpoch(expire * 1000) : null;
}

int _daysLeft(DateTime expiry) =>
    math.max(0, expiry.difference(DateTime.now()).inDays);

void _openAccount(BuildContext context, {required bool hasProfile}) {
  showYoukoMixAccountSheet(
    context,
    onShowRuntimeDetail: hasProfile
        ? () => showProfileDetailSheet(context)
        : null,
  );
}

const _nearlyUsedShare = 0.9;

String _percentOf(double share) => '${(share * 100).round()}%';

class ProfilesCard extends ConsumerWidget {
  const ProfilesCard({super.key});

  static const _soonDays = 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final mobile = !density.isDesktop;
    final compact = density.isCompact;
    final appLocalizations = context.appLocalizations;
    final auth = ref.watch(youkomixControllerProvider);
    final profile = ref.watch(currentProfileProvider);
    final user = auth.user;
    final sub = auth.subscription;
    final usage = _usageOf(auth.traffic, profile);
    final profileExpiry = _expiryOf(profile);
    final updatedAt = profile?.lastUpdateDate;
    final label = DashboardText.label(context);
    final figure = mobile
        ? AppTextStyle.title3
        : (compact ? AppTextStyle.callout : AppTextStyle.headline);
    final name = mobile || !compact
        ? AppTextStyle.headline
        : AppTextStyle.callout;

    final String titleText;
    if (user != null) {
      titleText = user.userName.isNotEmpty
          ? user.userName
          : (user.email.isNotEmpty ? user.email : appName);
    } else if (profile != null) {
      titleText = profile.realLabel;
    } else {
      titleText = appLocalizations.youkomixLogin;
    }

    String? endText;
    String? endTooltip;
    var endWarn = false;
    if (user != null) {
      if (user.isExpired || user.userClass <= 0) {
        endText = appLocalizations.youkomixExpired;
        endWarn = true;
      } else if (user.classExpire.isEmpty) {
        endText = appLocalizations.youkomixNeverExpire;
      } else {
        endText = appLocalizations.profileDaysLeft(user.classExpireDays);
        endTooltip = user.classExpire;
        endWarn = user.classExpireDays <= _soonDays;
      }
    } else if (profileExpiry != null) {
      final days = _daysLeft(profileExpiry);
      endText = appLocalizations.profileDaysLeft(days);
      endTooltip = appLocalizations.profileExpiresIn(profileExpiry.show, days);
      endWarn = days <= _soonDays;
    }

    final Widget? end = switch ((endText, endTooltip)) {
      (final text?, final tip?) => Tooltip(
        message: tip,
        child: Text(
          text,
          maxLines: 1,
          style: endWarn
              ? label.copyWith(color: DashboardColors.of(context).warn)
              : label,
        ),
      ),
      (final text?, null) => Text(
        text,
        maxLines: 1,
        style: endWarn
            ? label.copyWith(color: DashboardColors.of(context).warn)
            : label,
      ),
      _ => null,
    };

    final canSync = auth.isAuthenticated || profile != null;
    final sync = canSync ? _SyncButton(profile: profile) : null;
    final channelSwitch =
        !compact && auth.isAuthenticated && (sub?.exclusiveEnabled ?? false)
        ? const _SubChannelButton()
        : null;

    final nameRow = Row(
      spacing: 8,
      children: [
        Flexible(
          child: EmojiText(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: name.of(context, emphasized: true),
          ),
        ),
        if (user != null)
          DecoratedBox(
            decoration: ShapeDecoration(
              color: context.colorScheme.primary.opacity15,
              shape: AppShape.full,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                appLocalizations.youkomixLevelBadge(user.userClass),
                maxLines: 1,
                style: AppTextStyle.caption2
                    .of(context, emphasized: true)
                    .copyWith(color: context.colorScheme.primary),
              ),
            ),
          ),
      ],
    );

    final modeLabel = sub == null
        ? null
        : (auth.isExclusiveActive
              ? appLocalizations.youkomixSubModeExclusive
              : appLocalizations.youkomixSubModeStandard);

    return DashboardCard(
      semanticLabel: appLocalizations.youkomixAccount,
      onTap: mobile || !auth.isAuthenticated
          ? () => _openAccount(context, hasProfile: profile != null)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: mobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.account,
            title: appLocalizations.youkomixAccount,
            chevron: mobile,
            trailing: [
              if (mobile) ...[
                ?channelSwitch,
                ?sync,
              ] else
                Transform.translate(
                  offset: const Offset(8, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ?channelSwitch,
                      ?sync,
                      DashboardIconButton(
                        glyph: AppGlyphs.chevronForward,
                        tooltip: appLocalizations.details(
                          appLocalizations.youkomixAccount,
                        ),
                        onPressed: () =>
                            _openAccount(context, hasProfile: profile != null),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: mobile ? 12 : 10),
          if (compact && end != null)
            DashboardCappedRow(spacing: _rowGap, start: nameRow, end: end)
          else
            nameRow,
          if ((auth.isAuthenticated || profile != null) && !compact)
            LayoutBuilder(
              builder: (context, constraints) {
                final time = updatedAt?.getLastUpdateTimeDesc(context);
                final updated = time == null
                    ? null
                    : appLocalizations.profileUpdatedAt(time);
                final leftText = modeLabel ?? updated;
                final fallbackText = modeLabel ?? time;
                final fits =
                    leftText == null ||
                    _widthOf(leftText, label) +
                            _rowGap +
                            _widthOf(endText ?? '', label) <=
                        constraints.maxWidth;
                return Row(
                  spacing: _rowGap,
                  children: [
                    Expanded(
                      child: Text(
                        (fits ? leftText : fallbackText) ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: label,
                      ),
                    ),
                    ?end,
                  ],
                );
              },
            ),
          if (usage != null) ...[
            if (mobile) const SizedBox(height: 14) else const Spacer(),
            _UsageMeter(usage: usage, figure: figure, gap: mobile ? 8 : 6),
          ] else if (profile != null) ...[
            if (mobile) const SizedBox(height: 14) else const Spacer(),
            _ConfigStats(figure: figure),
          ] else if (auth.isAuthenticated) ...[
            if (mobile) const SizedBox(height: 14) else const Spacer(),
            Text(
              appLocalizations.youkomixOpenPanel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: label,
            ),
          ],
        ],
      ),
    );
  }
}

const _rowGap = 12.0;

double _widthOf(String text, TextStyle style) =>
    globalState.measure.computeTextSize(Text(text, style: style)).width;

class _SubChannelButton extends ConsumerWidget {
  const _SubChannelButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(youkomixControllerProvider);
    final sub = auth.subscription;
    if (!auth.isAuthenticated || sub == null || !sub.exclusiveEnabled) {
      return const SizedBox.shrink();
    }
    final appLocalizations = context.appLocalizations;
    final isExclusive = auth.isExclusiveActive;
    final disabled = auth.isSyncing || auth.isBusy;
    final exclusiveLabel = sub.exclusiveTitle.trim().isNotEmpty
        ? sub.exclusiveTitle.trim()
        : appLocalizations.youkomixSubChannelExclusive;
    return PopupAnchor(
      targetBuilder: (open) => DashboardIconButton(
        glyph: AppGlyphs.swap,
        tooltip: appLocalizations.youkomixSubChannel,
        onPressed: disabled ? null : open,
      ),
      popupBuilder: (_) => PopupMenu(
        items: [
          PopupMenuItem(
            label: exclusiveLabel,
            checked: isExclusive,
            onPressed: () => unawaited(
              ref
                  .read(youkomixControllerProvider.notifier)
                  .switchSubscriptionMode(YoukoMixSubPreference.exclusive),
            ),
          ),
          PopupMenuItem(
            label: appLocalizations.youkomixSubChannelStandard,
            checked: !isExclusive,
            onPressed: () => unawaited(
              ref
                  .read(youkomixControllerProvider.notifier)
                  .switchSubscriptionMode(YoukoMixSubPreference.standard),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncing = ref.watch(
      youkomixControllerProvider.select((s) => s.isSyncing || s.isBusy),
    );
    final profileUpdating = profile == null
        ? false
        : ref.watch(isUpdatingProvider(profile!.updatingKey));
    if (syncing || profileUpdating) {
      return const SizedBox.square(
        dimension: 32,
        child: Center(child: ActivityIndicator(size: 18)),
      );
    }
    return DashboardIconButton(
      glyph: AppGlyphs.sync,
      tooltip: context.appLocalizations.youkomixSyncNodes,
      onPressed: () => syncProfile(ref, profile),
    );
  }
}

class _ConfigStats extends ConsumerStatefulWidget {
  const _ConfigStats({required this.figure});

  final AppTextStyle figure;

  @override
  ConsumerState<_ConfigStats> createState() => _ConfigStatsState();
}

class _ConfigStatsState extends ConsumerState<_ConfigStats>
    with ConfigCountsWatch<_ConfigStats> {
  @override
  Widget build(BuildContext context) {
    watchConfigCounts();
    final providers = ref.watch(providersProvider);
    final appLocalizations = context.appLocalizations;
    final stats = switch (configCounts) {
      final counts? => profileStatsOf(counts, providers),
      null => null,
    };
    final figure = DashboardText.figure(
      context,
      widget.figure,
    ).copyWith(letterSpacing: 0);
    final label = DashboardText.label(context);
    Widget item(int? value, String name) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (value != null)
          Text(dashboardCount(value), maxLines: 1, style: figure)
        else if (configCountsFailed)
          Text('—', maxLines: 1, style: figure)
        else
          SkeletonText(width: widget.figure.size * 1.5, style: figure),
        Text(name, maxLines: 1, style: label),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              item(stats?.groups, appLocalizations.proxyGroup),
              item(stats?.proxies, appLocalizations.proxies),
              item(stats?.rules, appLocalizations.rules),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageMeter extends StatelessWidget {
  const _UsageMeter({
    required this.usage,
    required this.figure,
    required this.gap,
  });

  final _Usage usage;
  final AppTextStyle figure;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final percent = DashboardText.figure(
              context,
              figure,
            ).copyWith(letterSpacing: 0);
            final unit = DashboardText.unit(context, AppTextStyle.footnote);
            final used = ' ${context.appLocalizations.usedShort}';
            final traffic =
                '${dashboardTraffic(usage.used)} / ${dashboardTraffic(usage.total)}';
            final trafficStyle = AppTextStyle.footnote
                .of(context)
                .toTabular
                .copyWith(color: context.colorScheme.onSurfaceVariant);
            final showUnit =
                _widthOf(_percentOf(usage.share), percent) +
                    _widthOf(used, unit) +
                    _rowGap +
                    _widthOf(traffic, trafficStyle) <=
                constraints.maxWidth;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: _rowGap,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: _percentOf(usage.share), style: percent),
                      if (showUnit) TextSpan(text: used, style: unit),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    traffic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: trafficStyle,
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: gap),
        SizedBox(
          height: 12,
          child: CustomPaint(
            painter: _WavyProgressPainter(
              value: usage.share,
              active: usage.share >= _nearlyUsedShare
                  ? DashboardColors.of(context).warn
                  : context.colorScheme.primary,
              track: DashboardColors.of(context).tone2,
            ),
          ),
        ),
      ],
    );
  }
}

class _WavyProgressPainter extends CustomPainter {
  const _WavyProgressPainter({
    required this.value,
    required this.active,
    required this.track,
  });

  static const _stroke = 4.0;
  static const _amplitude = 3.0;
  static const _wavelength = 12.0;
  static const _gap = 6.0;
  static const _stop = 4.0;

  final double value;
  final Color active;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    const start = _stroke / 2;
    final end = size.width - _stroke / 2;
    final split = start + (end - start) * value;
    final paint = Paint()
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (value > 0) {
      final wave = Path()..moveTo(start, mid);
      for (var x = start; x <= split; x += 1) {
        wave.lineTo(
          x,
          mid + _amplitude * math.sin((x - start) / _wavelength * 2 * math.pi),
        );
      }
      canvas.drawPath(wave, paint..color = active);
    }
    final trackStart = value > 0 ? split + _gap + _stroke : start;
    if (trackStart < end - _stop) {
      canvas.drawLine(
        Offset(trackStart, mid),
        Offset(end - _stop - _gap, mid),
        paint..color = track,
      );
    }
    if (value < 1) {
      canvas.drawCircle(
        Offset(end - _stop / 2, mid),
        _stop / 2,
        Paint()..color = active,
      );
    }
  }

  @override
  bool shouldRepaint(_WavyProgressPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.active != active ||
      oldDelegate.track != track;
}
