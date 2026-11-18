import 'dart:convert';

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

double _toDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0.0;
  return 0.0;
}

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

List<String> parseYoukoMixEndpointList(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final seen = <String>{};
  final result = <String>[];
  for (final item in raw) {
    final text = _toString(item).trim().replaceAll(RegExp(r'/+$'), '');
    if (text.isEmpty) {
      continue;
    }
    final uri = Uri.tryParse(text);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      continue;
    }
    if (seen.add(text)) {
      result.add(text);
    }
  }
  return List.unmodifiable(result);
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

String stripAnnouncementMarkdown(String raw) {
  if (raw.isEmpty) return '';
  return raw
      .replaceAll('\r\n', '\n')
      .replaceAll(RegExp(r'```[\s\S]*?```'), '')
      .replaceAllMapped(
        RegExp(r'!\[([^\]]*)\]\([^)]+\)'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'),
        (match) => match.group(1) ?? '',
      )
      .replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*(?:[-*_]\s*){3,}$', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
      .replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1) ?? '')
      .replaceAllMapped(
        RegExp(r'\*\*\*([^*]+)\*\*\*'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(
        RegExp(r'\*\*([^*]+)\*\*'),
        (match) => match.group(1) ?? '',
      )
      .replaceAllMapped(RegExp(r'__([^_]+)__'), (match) => match.group(1) ?? '')
      .replaceAllMapped(RegExp(r'~~([^~]+)~~'), (match) => match.group(1) ?? '')
      .replaceAllMapped(
        RegExp(r'\*([^*\n]+)\*'),
        (match) => match.group(1) ?? '',
      )
      .replaceAll(_multiBlankLinePattern, '\n\n')
      .trim();
}

String stripAnnouncementMarkup(String raw) {
  if (raw.isEmpty) return '';
  return stripAnnouncementMarkdown(stripAnnouncementHtml(raw));
}

String htmlToMarkdownFallback(String html) {
  if (html.trim().isEmpty) return '';
  final converted = html
      .replaceAllMapped(
        RegExp(r'<h1[^>]*>([\s\S]*?)</h1>', caseSensitive: false),
        (match) => '\n# ${match.group(1) ?? ''}\n',
      )
      .replaceAllMapped(
        RegExp(r'<h2[^>]*>([\s\S]*?)</h2>', caseSensitive: false),
        (match) => '\n## ${match.group(1) ?? ''}\n',
      )
      .replaceAllMapped(
        RegExp(r'<h[3-6][^>]*>([\s\S]*?)</h[3-6]>', caseSensitive: false),
        (match) => '\n### ${match.group(1) ?? ''}\n',
      )
      .replaceAllMapped(
        RegExp(
          r'<(?:strong|b)[^>]*>([\s\S]*?)</(?:strong|b)>',
          caseSensitive: false,
        ),
        (match) => '**${match.group(1) ?? ''}**',
      )
      .replaceAllMapped(
        RegExp(r'<(?:em|i)[^>]*>([\s\S]*?)</(?:em|i)>', caseSensitive: false),
        (match) => '*${match.group(1) ?? ''}*',
      )
      .replaceAllMapped(
        RegExp(r'<code[^>]*>([\s\S]*?)</code>', caseSensitive: false),
        (match) => '`${match.group(1) ?? ''}`',
      )
      .replaceAllMapped(
        RegExp(
          r'''<a[^>]*href=['"](https?://[^'"]+)['"][^>]*>([\s\S]*?)</a>''',
          caseSensitive: false,
        ),
        (match) => '[${match.group(2) ?? ''}](${match.group(1) ?? ''})',
      )
      .replaceAllMapped(
        RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false),
        (match) => '\n- ${match.group(1) ?? ''}\n',
      );
  return stripAnnouncementHtml(converted);
}

bool isYoukoMixVersionBelow(String currentVersion, String minRequiredVersion) {
  String clean(String v) =>
      v.trim().replaceFirst(RegExp(r'^[vV]'), '').split(RegExp(r'[+-]')).first;

  final curText = clean(currentVersion);
  final minText = clean(minRequiredVersion);
  if (curText.isEmpty || minText.isEmpty) {
    return false;
  }
  final curParts = curText.split('.');
  final minParts = minText.split('.');
  final count = curParts.length > minParts.length
      ? curParts.length
      : minParts.length;
  for (var i = 0; i < count; i++) {
    final curNum = i < curParts.length ? (int.tryParse(curParts[i]) ?? 0) : 0;
    final minNum = i < minParts.length ? (int.tryParse(minParts[i]) ?? 0) : 0;
    if (curNum != minNum) {
      return curNum < minNum;
    }
  }
  return false;
}

@immutable
class YoukoMixCaptchaChallenge {
  final String captchaId;
  final String imageBase64;
  final Uint8List imageBytes;
  final int expiresIn;

  const YoukoMixCaptchaChallenge({
    required this.captchaId,
    required this.imageBase64,
    required this.imageBytes,
    this.expiresIn = 180,
  });

  bool get isValid => captchaId.isNotEmpty && imageBytes.isNotEmpty;

  factory YoukoMixCaptchaChallenge.fromJson(Map<String, Object?> json) {
    final id = _toString(json['captcha_id']).trim();
    final rawB64 = _toString(json['image_base64']).trim();
    final strippedB64 = rawB64.contains(',')
        ? rawB64.split(',').last.trim()
        : rawB64;
    Uint8List decodedBytes = Uint8List(0);
    if (strippedB64.isNotEmpty) {
      try {
        decodedBytes = Uint8List.fromList(base64Decode(strippedB64));
      } on FormatException {
        decodedBytes = Uint8List(0);
      }
    }
    final ttl = _toInt(json['expires_in']);
    return YoukoMixCaptchaChallenge(
      captchaId: id,
      imageBase64: strippedB64,
      imageBytes: decodedBytes,
      expiresIn: ttl > 0 ? ttl : 180,
    );
  }

  Map<String, Object?> toJson() => {
    'captcha_id': captchaId,
    'image_base64': imageBase64,
    'expires_in': expiresIn,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixCaptchaChallenge &&
          other.captchaId == captchaId &&
          other.imageBase64 == imageBase64 &&
          other.expiresIn == expiresIn;

  @override
  int get hashCode => Object.hash(captchaId, imageBase64, expiresIn);
}

@immutable
class YoukoMixMeta {
  final String appName;
  final String baseUrl;
  final List<String> apiEndpoints;
  final String downloadBaseUrl;
  final bool captchaEnabled;
  final String captchaMode;
  final String minClientVersion;
  final bool e2eeRequired;
  final String registerUrl;
  final String passwordResetUrl;
  final String webAuthUrl;

  const YoukoMixMeta({
    this.appName = '',
    this.baseUrl = '',
    this.apiEndpoints = const [],
    this.downloadBaseUrl = '',
    this.captchaEnabled = false,
    this.captchaMode = 'none',
    this.minClientVersion = '',
    this.e2eeRequired = false,
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
    final rawMode = _toString(json['captcha_mode']).trim();
    final rawDownloadBase = _toString(
      json['download_base_url'],
    ).trim().replaceAll(RegExp(r'/+$'), '');
    final webAuth = _toString(json['web_auth_url']).trim();
    final register = _toString(json['register_url']).trim();
    final reset = _toString(json['password_reset_url']).trim();
    final endpoints = parseYoukoMixEndpointList(json['api_endpoints']);
    return YoukoMixMeta(
      appName: _toString(json['app_name']),
      baseUrl: resolvedBase,
      apiEndpoints: endpoints,
      downloadBaseUrl: rawDownloadBase.isNotEmpty
          ? rawDownloadBase
          : resolvedBase,
      captchaEnabled: captcha,
      captchaMode: rawMode.isNotEmpty
          ? rawMode
          : (captcha ? 'native_image' : 'none'),
      minClientVersion: _toString(json['min_client_version']).trim(),
      e2eeRequired: _toBool(json['e2ee_required']),
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
    'api_endpoints': apiEndpoints,
    'download_base_url': downloadBaseUrl,
    'login_captcha_enabled': captchaEnabled,
    'captcha_mode': captchaMode,
    'min_client_version': minClientVersion,
    'e2ee_required': e2eeRequired,
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
          const ListEquality<String>().equals(
            other.apiEndpoints,
            apiEndpoints,
          ) &&
          other.downloadBaseUrl == downloadBaseUrl &&
          other.captchaEnabled == captchaEnabled &&
          other.captchaMode == captchaMode &&
          other.minClientVersion == minClientVersion &&
          other.e2eeRequired == e2eeRequired &&
          other.registerUrl == registerUrl &&
          other.passwordResetUrl == passwordResetUrl &&
          other.webAuthUrl == webAuthUrl;

  @override
  int get hashCode => Object.hash(
    appName,
    baseUrl,
    const ListEquality<String>().hash(apiEndpoints),
    downloadBaseUrl,
    captchaEnabled,
    captchaMode,
    minClientVersion,
    e2eeRequired,
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
  final double nodeSpeedLimit;

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
    this.nodeSpeedLimit = 0,
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
      nodeSpeedLimit: _toDouble(json['node_speedlimit']),
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
    'node_speedlimit': nodeSpeedLimit,
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
          other.nodeIpLimit == nodeIpLimit &&
          other.nodeSpeedLimit == nodeSpeedLimit;

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
    nodeSpeedLimit,
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

enum YoukoMixSubPreference {
  auto('auto'),
  exclusive('exclusive'),
  standard('standard');

  final String apiValue;

  const YoukoMixSubPreference(this.apiValue);

  static YoukoMixSubPreference fromString(Object? raw) {
    return switch (raw?.toString().trim().toLowerCase()) {
      'exclusive' => YoukoMixSubPreference.exclusive,
      'standard' => YoukoMixSubPreference.standard,
      _ => YoukoMixSubPreference.auto,
    };
  }
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

  YoukoMixSubscriptionState copyWith({
    bool? enabled,
    bool? exclusiveEnabled,
    String? exclusiveTitle,
    String? activeMode,
    int? updateIntervalHours,
  }) {
    return YoukoMixSubscriptionState(
      enabled: enabled ?? this.enabled,
      exclusiveEnabled: exclusiveEnabled ?? this.exclusiveEnabled,
      exclusiveTitle: exclusiveTitle ?? this.exclusiveTitle,
      activeMode: activeMode ?? this.activeMode,
      updateIntervalHours: updateIntervalHours ?? this.updateIntervalHours,
    );
  }

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
    return stripAnnouncementMarkup(preferred);
  }

  String get richMarkdownSource {
    if (markdown.trim().isNotEmpty) {
      return markdown.trim();
    }
    return htmlToMarkdownFallback(content);
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
class YoukoMixUpgradeNotice {
  final bool enabled;
  final String mode;
  final int cutoverAt;
  final String title;
  final String message;

  const YoukoMixUpgradeNotice({
    this.enabled = false,
    this.mode = 'compat',
    this.cutoverAt = 0,
    this.title = '',
    this.message = '',
  });

  bool get isEnforced => mode == 'required';

  bool get shouldDisplay =>
      enabled && (title.trim().isNotEmpty || message.trim().isNotEmpty);

  DateTime? get cutoverDate => cutoverAt > 0
      ? DateTime.fromMillisecondsSinceEpoch(cutoverAt * 1000)
      : null;

  factory YoukoMixUpgradeNotice.fromJson(Map<String, Object?> json) {
    final rawMode = _toString(json['mode']).trim().toLowerCase();
    return YoukoMixUpgradeNotice(
      enabled: _toBool(json['enabled']),
      mode: rawMode.isEmpty ? 'compat' : rawMode,
      cutoverAt: _toInt(json['cutover_at']),
      title: _toString(json['title']).trim(),
      message: _toString(json['message']).trim(),
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'mode': mode,
    'cutover_at': cutoverAt,
    'title': title,
    'message': message,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixUpgradeNotice &&
          other.enabled == enabled &&
          other.mode == mode &&
          other.cutoverAt == cutoverAt &&
          other.title == title &&
          other.message == message;

  @override
  int get hashCode => Object.hash(enabled, mode, cutoverAt, title, message);
}

@immutable
class YoukoMixBootstrap {
  final YoukoMixUser user;
  final YoukoMixTraffic traffic;
  final YoukoMixSubscriptionState subscription;
  final List<YoukoMixAnnouncement> announcements;
  final YoukoMixLinks links;
  final List<String> apiEndpoints;
  final String downloadBaseUrl;
  final YoukoMixUpgradeNotice? upgradeNotice;

  const YoukoMixBootstrap({
    this.user = const YoukoMixUser(),
    this.traffic = const YoukoMixTraffic(),
    this.subscription = const YoukoMixSubscriptionState(),
    this.announcements = const [],
    this.links = const YoukoMixLinks(),
    this.apiEndpoints = const [],
    this.downloadBaseUrl = '',
    this.upgradeNotice,
  });

  YoukoMixBootstrap copyWith({
    YoukoMixUser? user,
    YoukoMixTraffic? traffic,
    YoukoMixSubscriptionState? subscription,
    List<YoukoMixAnnouncement>? announcements,
    YoukoMixLinks? links,
    List<String>? apiEndpoints,
    String? downloadBaseUrl,
    YoukoMixUpgradeNotice? upgradeNotice,
    bool clearUpgradeNotice = false,
  }) {
    return YoukoMixBootstrap(
      user: user ?? this.user,
      traffic: traffic ?? this.traffic,
      subscription: subscription ?? this.subscription,
      announcements: announcements ?? this.announcements,
      links: links ?? this.links,
      apiEndpoints: apiEndpoints ?? this.apiEndpoints,
      downloadBaseUrl: downloadBaseUrl ?? this.downloadBaseUrl,
      upgradeNotice: clearUpgradeNotice
          ? null
          : (upgradeNotice ?? this.upgradeNotice),
    );
  }

  factory YoukoMixBootstrap.fromJson(Map<String, Object?> json) {
    final userRaw = json['user'];
    final trafficRaw = json['traffic'];
    final subRaw = json['subscription'];
    final annRaw = json['announcements'];
    final linksRaw = json['links'];
    final panelRaw = json['panel'];
    final upgradeNoticeRaw = json['upgrade_notice'];
    YoukoMixLinks resolvedLinks = const YoukoMixLinks();
    List<String> resolvedEndpoints = parseYoukoMixEndpointList(
      json['api_endpoints'],
    );
    String resolvedDownloadBase = _toString(
      json['download_base_url'],
    ).trim().replaceAll(RegExp(r'/+$'), '');
    YoukoMixUpgradeNotice? resolvedUpgradeNotice;
    if (upgradeNoticeRaw is Map) {
      final parsedNotice = YoukoMixUpgradeNotice.fromJson(
        Map<String, Object?>.from(upgradeNoticeRaw),
      );
      if (parsedNotice.shouldDisplay) {
        resolvedUpgradeNotice = parsedNotice;
      }
    }

    if (panelRaw is Map) {
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
      final panelEndpoints = parseYoukoMixEndpointList(
        panelMap['api_endpoints'],
      );
      if (panelEndpoints.isNotEmpty) {
        resolvedEndpoints = panelEndpoints;
      }
      final panelDl = _toString(
        panelMap['download_base_url'],
      ).trim().replaceAll(RegExp(r'/+$'), '');
      if (panelDl.isNotEmpty) {
        resolvedDownloadBase = panelDl;
      }
    }
    if (linksRaw is Map) {
      resolvedLinks = YoukoMixLinks.fromJson(
        Map<String, Object?>.from(linksRaw),
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
      apiEndpoints: resolvedEndpoints,
      downloadBaseUrl: resolvedDownloadBase,
      upgradeNotice: resolvedUpgradeNotice,
    );
  }

  Map<String, Object?> toJson() => {
    'user': user.toJson(),
    'traffic': traffic.toJson(),
    'subscription': subscription.toJson(),
    'announcements': [for (final item in announcements) item.toJson()],
    'links': links.toJson(),
    if (apiEndpoints.isNotEmpty) 'api_endpoints': apiEndpoints,
    if (downloadBaseUrl.isNotEmpty) 'download_base_url': downloadBaseUrl,
    if (upgradeNotice != null) 'upgrade_notice': upgradeNotice!.toJson(),
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
          other.links == links &&
          const ListEquality<String>().equals(
            other.apiEndpoints,
            apiEndpoints,
          ) &&
          other.downloadBaseUrl == downloadBaseUrl &&
          other.upgradeNotice == upgradeNotice;

  @override
  int get hashCode => Object.hash(
    user,
    traffic,
    subscription,
    const ListEquality<YoukoMixAnnouncement>().hash(announcements),
    links,
    const ListEquality<String>().hash(apiEndpoints),
    downloadBaseUrl,
    upgradeNotice,
  );
}

@immutable
class YoukoMixSession {
  final String serverUrl;
  final String accessToken;
  final int expiresAt;
  final YoukoMixSubPreference preferredSubMode;
  final List<String> apiEndpoints;
  final YoukoMixBootstrap? bootstrap;
  final int lastReadAnnouncementId;
  final int lastPromptedPinnedId;

  const YoukoMixSession({
    required this.serverUrl,
    required this.accessToken,
    this.expiresAt = 0,
    this.preferredSubMode = YoukoMixSubPreference.auto,
    this.apiEndpoints = const [],
    this.bootstrap,
    this.lastReadAnnouncementId = 0,
    this.lastPromptedPinnedId = 0,
  });

  YoukoMixSession copyWith({
    String? serverUrl,
    String? accessToken,
    int? expiresAt,
    YoukoMixSubPreference? preferredSubMode,
    List<String>? apiEndpoints,
    YoukoMixBootstrap? bootstrap,
    int? lastReadAnnouncementId,
    int? lastPromptedPinnedId,
  }) {
    return YoukoMixSession(
      serverUrl: serverUrl ?? this.serverUrl,
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
      preferredSubMode: preferredSubMode ?? this.preferredSubMode,
      apiEndpoints: apiEndpoints ?? this.apiEndpoints,
      bootstrap: bootstrap ?? this.bootstrap,
      lastReadAnnouncementId:
          lastReadAnnouncementId ?? this.lastReadAnnouncementId,
      lastPromptedPinnedId: lastPromptedPinnedId ?? this.lastPromptedPinnedId,
    );
  }

  factory YoukoMixSession.fromJson(
    Map<String, Object?> json, {
    String fallbackServerUrl = '',
  }) {
    final bootstrapRaw = json['bootstrap'];
    final parsedBootstrap = bootstrapRaw is Map
        ? YoukoMixBootstrap.fromJson(Map<String, Object?>.from(bootstrapRaw))
        : null;
    final rawServer = _toString(json['server_url']).trim();
    final rawToken = _toString(json['access_token']).isNotEmpty
        ? _toString(json['access_token'])
        : _toString(json['token']);
    final explicitEndpoints = parseYoukoMixEndpointList(json['api_endpoints']);
    return YoukoMixSession(
      serverUrl: rawServer.isNotEmpty ? rawServer : fallbackServerUrl,
      accessToken: rawToken,
      expiresAt: _toInt(json['expires_at']),
      preferredSubMode: YoukoMixSubPreference.fromString(
        json['preferred_sub_mode'],
      ),
      apiEndpoints: explicitEndpoints.isNotEmpty
          ? explicitEndpoints
          : (parsedBootstrap?.apiEndpoints ?? const []),
      bootstrap: parsedBootstrap,
      lastReadAnnouncementId: _toInt(json['last_read_announcement_id']),
      lastPromptedPinnedId: _toInt(json['last_prompted_pinned_id']),
    );
  }

  Map<String, Object?> toJson() => {
    'server_url': serverUrl,
    'access_token': accessToken,
    'expires_at': expiresAt,
    'preferred_sub_mode': preferredSubMode.apiValue,
    if (apiEndpoints.isNotEmpty) 'api_endpoints': apiEndpoints,
    if (bootstrap != null) 'bootstrap': bootstrap!.toJson(),
    if (lastReadAnnouncementId > 0)
      'last_read_announcement_id': lastReadAnnouncementId,
    if (lastPromptedPinnedId > 0)
      'last_prompted_pinned_id': lastPromptedPinnedId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixSession &&
          other.serverUrl == serverUrl &&
          other.accessToken == accessToken &&
          other.expiresAt == expiresAt &&
          other.preferredSubMode == preferredSubMode &&
          const ListEquality<String>().equals(
            other.apiEndpoints,
            apiEndpoints,
          ) &&
          other.bootstrap == bootstrap &&
          other.lastReadAnnouncementId == lastReadAnnouncementId &&
          other.lastPromptedPinnedId == lastPromptedPinnedId;

  @override
  int get hashCode => Object.hash(
    serverUrl,
    accessToken,
    expiresAt,
    preferredSubMode,
    const ListEquality<String>().hash(apiEndpoints),
    bootstrap,
    lastReadAnnouncementId,
    lastPromptedPinnedId,
  );
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
  final YoukoMixCaptchaChallenge? challenge;
  final String webAuthUrl;
  final String message;

  const YoukoMixLoginCaptchaRequired({
    this.challenge,
    required this.webAuthUrl,
    required this.message,
  });
}
