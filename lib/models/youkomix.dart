import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

const defaultYoukoMixServerUrl = String.fromEnvironment(
  'YOUKOMIX_SERVER_URL',
  defaultValue: '',
);

const youkomixManagedProfileId = 20261115;

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _toString(Object? value) => value?.toString() ?? '';

String _toMoney(Object? value) {
  if (value is num) return value.toStringAsFixed(2);
  if (value is String && value.trim().isNotEmpty) {
    final parsed = double.tryParse(value.trim());
    return parsed != null ? parsed.toStringAsFixed(2) : value.trim();
  }
  return '0.00';
}

bool _toBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

final _htmlTagPattern = RegExp(r'<[^>]*>');
final _multiBlankLinePattern = RegExp(r'\n{3,}');

String stripAnnouncementHtml(String raw) {
  if (raw.isEmpty) return '';
  final withBreaks = raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');
  final stripped = withBreaks
      .replaceAll(_htmlTagPattern, '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&#39;', "'");
  return stripped.replaceAll(_multiBlankLinePattern, '\n\n').trim();
}

@immutable
class YoukoMixMeta {
  final String appName;
  final String baseUrl;
  final bool captchaEnabled;
  final String registerUrl;
  final String passwordResetUrl;
  final String webAuthUrl;

  const YoukoMixMeta({
    this.appName = '',
    this.baseUrl = '',
    this.captchaEnabled = false,
    this.registerUrl = '',
    this.passwordResetUrl = '',
    this.webAuthUrl = '',
  });

  factory YoukoMixMeta.fromJson(
    Map<String, Object?> json, {
    String fallbackBaseUrl = '',
  }) {
    final rawBase = _toString(json['base_url']).trim();
    final resolvedBase = (rawBase.isNotEmpty ? rawBase : fallbackBaseUrl)
        .replaceAll(RegExp(r'/+$'), '');
    final captcha = json.containsKey('login_captcha_enabled')
        ? _toBool(json['login_captcha_enabled'])
        : _toBool(json['captcha_enabled']);
    final webAuth = _toString(json['web_auth_url']).trim();
    final register = _toString(json['register_url']).trim();
    final reset = _toString(json['password_reset_url']).trim();
    return YoukoMixMeta(
      appName: _toString(json['app_name']),
      baseUrl: resolvedBase,
      captchaEnabled: captcha,
      webAuthUrl: webAuth.isNotEmpty
          ? webAuth
          : (resolvedBase.isNotEmpty ? '$resolvedBase/user/client-auth' : ''),
      registerUrl: register.isNotEmpty
          ? register
          : (resolvedBase.isNotEmpty ? '$resolvedBase/auth/register' : ''),
      passwordResetUrl: reset.isNotEmpty
          ? reset
          : (resolvedBase.isNotEmpty ? '$resolvedBase/password/reset' : ''),
    );
  }

  Map<String, Object?> toJson() => {
    'app_name': appName,
    'base_url': baseUrl,
    'login_captcha_enabled': captchaEnabled,
    'register_url': registerUrl,
    'password_reset_url': passwordResetUrl,
    'web_auth_url': webAuthUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixMeta &&
          other.appName == appName &&
          other.baseUrl == baseUrl &&
          other.captchaEnabled == captchaEnabled &&
          other.registerUrl == registerUrl &&
          other.passwordResetUrl == passwordResetUrl &&
          other.webAuthUrl == webAuthUrl;

  @override
  int get hashCode => Object.hash(
    appName,
    baseUrl,
    captchaEnabled,
    registerUrl,
    passwordResetUrl,
    webAuthUrl,
  );
}

@immutable
class YoukoMixUser {
  final int id;
  final String email;
  final String userName;
  final int userClass;
  final String classExpire;
  final int classExpireDays;
  final bool isExpired;
  final String money;
  final int onlineIpCount;
  final int nodeIpLimit;

  const YoukoMixUser({
    this.id = 0,
    this.email = '',
    this.userName = '',
    this.userClass = 0,
    this.classExpire = '',
    this.classExpireDays = 0,
    this.isExpired = false,
    this.money = '0.00',
    this.onlineIpCount = 0,
    this.nodeIpLimit = 0,
  });

  static DateTime? parseExpireDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.startsWith('1970-') || text.startsWith('0000-')) {
      return null;
    }
    final normalized = text.contains('T') ? text : text.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  DateTime? get classExpireDate => parseExpireDate(classExpire);

  factory YoukoMixUser.fromJson(Map<String, Object?> json) {
    final classExpire = _toString(json['class_expire']);
    final expireDate = parseExpireDate(classExpire);
    final expired = json.containsKey('is_expired')
        ? _toBool(json['is_expired'])
        : (expireDate != null && expireDate.isBefore(DateTime.now()));
    return YoukoMixUser(
      id: _toInt(json['id']),
      email: _toString(json['email']),
      userName: _toString(json['user_name']),
      userClass: _toInt(json['class']),
      classExpire: classExpire,
      classExpireDays: _toInt(json['class_expire_days']),
      isExpired: expired,
      money: _toMoney(json['money']),
      onlineIpCount: _toInt(json['online_ip_count']),
      nodeIpLimit: _toInt(json['node_iplimit']),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'user_name': userName,
    'class': userClass,
    'class_expire': classExpire,
    'class_expire_days': classExpireDays,
    'is_expired': isExpired,
    'money': money,
    'online_ip_count': onlineIpCount,
    'node_iplimit': nodeIpLimit,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixUser &&
          other.id == id &&
          other.email == email &&
          other.userName == userName &&
          other.userClass == userClass &&
          other.classExpire == classExpire &&
          other.classExpireDays == classExpireDays &&
          other.isExpired == isExpired &&
          other.money == money &&
          other.onlineIpCount == onlineIpCount &&
          other.nodeIpLimit == nodeIpLimit;

  @override
  int get hashCode => Object.hash(
    id,
    email,
    userName,
    userClass,
    classExpire,
    classExpireDays,
    isExpired,
    money,
    onlineIpCount,
    nodeIpLimit,
  );
}

@immutable
class YoukoMixTraffic {
  final int upload;
  final int download;
  final int used;
  final int today;
  final int total;
  final int remaining;

  const YoukoMixTraffic({
    this.upload = 0,
    this.download = 0,
    this.used = 0,
    this.today = 0,
    this.total = 0,
    this.remaining = 0,
  });

  factory YoukoMixTraffic.fromJson(Map<String, Object?> json) {
    final upload = _toInt(json['upload']);
    final download = _toInt(json['download']);
    final total = _toInt(json['total']);
    final used = json.containsKey('used')
        ? _toInt(json['used'])
        : upload + download;
    final remaining = json.containsKey('remaining')
        ? _toInt(json['remaining'])
        : (total > used ? total - used : 0);
    return YoukoMixTraffic(
      upload: upload,
      download: download,
      used: used,
      today: _toInt(json['today']),
      total: total,
      remaining: remaining,
    );
  }

  Map<String, Object?> toJson() => {
    'upload': upload,
    'download': download,
    'used': used,
    'today': today,
    'total': total,
    'remaining': remaining,
  };

  double get usageRatio => total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixTraffic &&
          other.upload == upload &&
          other.download == download &&
          other.used == used &&
          other.today == today &&
          other.total == total &&
          other.remaining == remaining;

  @override
  int get hashCode =>
      Object.hash(upload, download, used, today, total, remaining);
}

@immutable
class YoukoMixSubscriptionState {
  final bool enabled;
  final bool exclusiveEnabled;
  final String exclusiveTitle;
  final String activeMode;
  final int updateIntervalHours;

  const YoukoMixSubscriptionState({
    this.enabled = true,
    this.exclusiveEnabled = false,
    this.exclusiveTitle = '',
    this.activeMode = 'standard',
    this.updateIntervalHours = 6,
  });

  bool get isExclusive => activeMode == 'exclusive';

  factory YoukoMixSubscriptionState.fromJson(Map<String, Object?> json) {
    final mode = _toString(json['active_mode']);
    final interval = _toInt(json['update_interval_hours']);
    return YoukoMixSubscriptionState(
      enabled: _toBool(json['enabled'], fallback: true),
      exclusiveEnabled: _toBool(json['exclusive_enabled']),
      exclusiveTitle: _toString(json['exclusive_title']),
      activeMode: mode.isEmpty ? 'standard' : mode,
      updateIntervalHours: interval > 0 ? interval : 6,
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'exclusive_enabled': exclusiveEnabled,
    'exclusive_title': exclusiveTitle,
    'active_mode': activeMode,
    'update_interval_hours': updateIntervalHours,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixSubscriptionState &&
          other.enabled == enabled &&
          other.exclusiveEnabled == exclusiveEnabled &&
          other.exclusiveTitle == exclusiveTitle &&
          other.activeMode == activeMode &&
          other.updateIntervalHours == updateIntervalHours;

  @override
  int get hashCode => Object.hash(
    enabled,
    exclusiveEnabled,
    exclusiveTitle,
    activeMode,
    updateIntervalHours,
  );
}

@immutable
class YoukoMixAnnouncement {
  final int id;
  final String date;
  final String title;
  final String content;
  final String markdown;
  final bool isPinned;

  const YoukoMixAnnouncement({
    this.id = 0,
    this.date = '',
    this.title = '',
    this.content = '',
    this.markdown = '',
    this.isPinned = false,
  });

  String get displayBody {
    final preferred = markdown.trim().isNotEmpty ? markdown : content;
    return stripAnnouncementHtml(preferred);
  }

  factory YoukoMixAnnouncement.fromJson(Map<String, Object?> json) {
    return YoukoMixAnnouncement(
      id: _toInt(json['id']),
      date: _toString(json['date']),
      title: _toString(json['title']),
      content: _toString(json['content']),
      markdown: _toString(json['markdown']),
      isPinned: _toBool(json['is_pinned']),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'date': date,
    'title': title,
    'content': content,
    'markdown': markdown,
    'is_pinned': isPinned,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixAnnouncement &&
          other.id == id &&
          other.date == date &&
          other.title == title &&
          other.content == content &&
          other.markdown == markdown &&
          other.isPinned == isPinned;

  @override
  int get hashCode => Object.hash(id, date, title, content, markdown, isPinned);
}

@immutable
class YoukoMixLinks {
  final String panelUrl;
  final String webAuthUrl;

  const YoukoMixLinks({this.panelUrl = '', this.webAuthUrl = ''});

  factory YoukoMixLinks.fromJson(Map<String, Object?> json) {
    return YoukoMixLinks(
      panelUrl: _toString(json['panel_url']),
      webAuthUrl: _toString(json['web_auth_url']),
    );
  }

  Map<String, Object?> toJson() => {
    'panel_url': panelUrl,
    'web_auth_url': webAuthUrl,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixLinks &&
          other.panelUrl == panelUrl &&
          other.webAuthUrl == webAuthUrl;

  @override
  int get hashCode => Object.hash(panelUrl, webAuthUrl);
}

@immutable
class YoukoMixBootstrap {
  final YoukoMixUser user;
  final YoukoMixTraffic traffic;
  final YoukoMixSubscriptionState subscription;
  final List<YoukoMixAnnouncement> announcements;
  final YoukoMixLinks links;

  const YoukoMixBootstrap({
    this.user = const YoukoMixUser(),
    this.traffic = const YoukoMixTraffic(),
    this.subscription = const YoukoMixSubscriptionState(),
    this.announcements = const [],
    this.links = const YoukoMixLinks(),
  });

  factory YoukoMixBootstrap.fromJson(Map<String, Object?> json) {
    final userRaw = json['user'];
    final trafficRaw = json['traffic'];
    final subRaw = json['subscription'];
    final annRaw = json['announcements'];
    final linksRaw = json['links'];
    final panelRaw = json['panel'];
    YoukoMixLinks resolvedLinks = const YoukoMixLinks();
    if (linksRaw is Map) {
      resolvedLinks = YoukoMixLinks.fromJson(
        Map<String, Object?>.from(linksRaw),
      );
    } else if (panelRaw is Map) {
      final panelMap = Map<String, Object?>.from(panelRaw);
      final baseUrl = _toString(
        panelMap['base_url'],
      ).replaceAll(RegExp(r'/+$'), '');
      final userCenter = _toString(panelMap['user_center_url']);
      resolvedLinks = YoukoMixLinks(
        panelUrl: userCenter.isNotEmpty
            ? userCenter
            : (baseUrl.isNotEmpty ? '$baseUrl/user' : ''),
        webAuthUrl: baseUrl.isNotEmpty ? '$baseUrl/user/client-auth' : '',
      );
    }
    return YoukoMixBootstrap(
      user: userRaw is Map
          ? YoukoMixUser.fromJson(Map<String, Object?>.from(userRaw))
          : const YoukoMixUser(),
      traffic: trafficRaw is Map
          ? YoukoMixTraffic.fromJson(Map<String, Object?>.from(trafficRaw))
          : const YoukoMixTraffic(),
      subscription: subRaw is Map
          ? YoukoMixSubscriptionState.fromJson(
              Map<String, Object?>.from(subRaw),
            )
          : const YoukoMixSubscriptionState(),
      announcements: [
        if (annRaw is List)
          for (final item in annRaw)
            if (item is Map)
              YoukoMixAnnouncement.fromJson(Map<String, Object?>.from(item)),
      ],
      links: resolvedLinks,
    );
  }

  Map<String, Object?> toJson() => {
    'user': user.toJson(),
    'traffic': traffic.toJson(),
    'subscription': subscription.toJson(),
    'announcements': [for (final item in announcements) item.toJson()],
    'links': links.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixBootstrap &&
          other.user == user &&
          other.traffic == traffic &&
          other.subscription == subscription &&
          const ListEquality<YoukoMixAnnouncement>().equals(
            other.announcements,
            announcements,
          ) &&
          other.links == links;

  @override
  int get hashCode => Object.hash(
    user,
    traffic,
    subscription,
    const ListEquality<YoukoMixAnnouncement>().hash(announcements),
    links,
  );
}

@immutable
class YoukoMixSession {
  final String serverUrl;
  final String accessToken;
  final int expiresAt;
  final YoukoMixBootstrap? bootstrap;

  const YoukoMixSession({
    required this.serverUrl,
    required this.accessToken,
    this.expiresAt = 0,
    this.bootstrap,
  });

  YoukoMixSession copyWith({
    String? serverUrl,
    String? accessToken,
    int? expiresAt,
    YoukoMixBootstrap? bootstrap,
  }) {
    return YoukoMixSession(
      serverUrl: serverUrl ?? this.serverUrl,
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
      bootstrap: bootstrap ?? this.bootstrap,
    );
  }

  factory YoukoMixSession.fromJson(
    Map<String, Object?> json, {
    String fallbackServerUrl = '',
  }) {
    final bootstrapRaw = json['bootstrap'];
    final rawServer = _toString(json['server_url']).trim();
    final rawToken = _toString(json['access_token']).isNotEmpty
        ? _toString(json['access_token'])
        : _toString(json['token']);
    return YoukoMixSession(
      serverUrl: rawServer.isNotEmpty ? rawServer : fallbackServerUrl,
      accessToken: rawToken,
      expiresAt: _toInt(json['expires_at']),
      bootstrap: bootstrapRaw is Map
          ? YoukoMixBootstrap.fromJson(Map<String, Object?>.from(bootstrapRaw))
          : null,
    );
  }

  Map<String, Object?> toJson() => {
    'server_url': serverUrl,
    'access_token': accessToken,
    'expires_at': expiresAt,
    if (bootstrap != null) 'bootstrap': bootstrap!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixSession &&
          other.serverUrl == serverUrl &&
          other.accessToken == accessToken &&
          other.expiresAt == expiresAt &&
          other.bootstrap == bootstrap;

  @override
  int get hashCode => Object.hash(serverUrl, accessToken, expiresAt, bootstrap);
}

sealed class YoukoMixLoginOutcome {
  const YoukoMixLoginOutcome();
}

final class YoukoMixLoginAuthenticated extends YoukoMixLoginOutcome {
  final YoukoMixSession session;

  const YoukoMixLoginAuthenticated(this.session);
}

final class YoukoMixLoginMfaRequired extends YoukoMixLoginOutcome {
  final String challengeToken;
  final int expiresIn;
  final String webAuthUrl;

  const YoukoMixLoginMfaRequired({
    required this.challengeToken,
    this.expiresIn = 300,
    this.webAuthUrl = '',
  });
}

final class YoukoMixLoginCaptchaRequired extends YoukoMixLoginOutcome {
  final String webAuthUrl;
  final String message;

  const YoukoMixLoginCaptchaRequired({
    required this.webAuthUrl,
    required this.message,
  });
}
