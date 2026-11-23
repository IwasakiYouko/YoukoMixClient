import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'constant.dart';
import 'request.dart';
import 'youkomix_crypto.dart';
import 'youkomix_storage.dart';

String normalizeYoukoMixServerUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    final l10n = AppLocalizations.maybeCurrent;
    throw YoukoMixApiException(
      message: l10n?.youkomixErrEmptyServerUrl ?? '请输入面板地址',
      errorCode: 'invalid_server_url',
    );
  }
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    final l10n = AppLocalizations.maybeCurrent;
    throw YoukoMixApiException(
      message: l10n?.youkomixErrInvalidServerUrl ?? '面板地址格式无效，请使用 https:// 域名',
      errorCode: 'invalid_server_url',
    );
  }
  final cleanPath = uri.path.replaceAll(RegExp(r'/+$'), '');
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: cleanPath,
  ).toString().replaceAll(RegExp(r'/+$'), '');
}

@immutable
class YoukoMixApiException implements Exception {
  final String message;
  final String errorCode;
  final int? statusCode;
  final Map<String, Object?> data;
  final bool fromAuthenticatedEnvelope;

  const YoukoMixApiException({
    required this.message,
    this.errorCode = 'api_error',
    this.statusCode,
    this.data = const {},
    this.fromAuthenticatedEnvelope = false,
  });

  bool get isUnauthorized =>
      fromAuthenticatedEnvelope &&
      statusCode == 401 &&
      (errorCode == 'unauthorized' ||
          errorCode == 'exchange_expired' ||
          errorCode == 'mfa_expired');

  bool get isSessionInvalid =>
      fromAuthenticatedEnvelope &&
      statusCode == 401 &&
      errorCode == 'unauthorized';

  bool get isUpgradeRequired =>
      statusCode == 426 || errorCode == 'client_upgrade_required';

  @override
  String toString() => message;
}

@immutable
class YoukoMixSubscriptionPayload {
  final Uint8List bytes;
  final String mode;
  final String title;
  final String? userInfoHeader;
  final int updateIntervalHours;

  const YoukoMixSubscriptionPayload({
    required this.bytes,
    required this.mode,
    required this.title,
    this.userInfoHeader,
    this.updateIntervalHours = 6,
  });
}

@immutable
class YoukoMixReleaseAsset {
  final String url;
  final String sha256;
  final int size;

  const YoukoMixReleaseAsset({
    required this.url,
    required this.sha256,
    this.size = 0,
  });

  factory YoukoMixReleaseAsset.fromJson(Map<String, Object?> json) {
    final sizeVal = json['size'];
    return YoukoMixReleaseAsset(
      url: json['url']?.toString() ?? '',
      sha256: (json['sha256']?.toString() ?? '').toLowerCase(),
      size: sizeVal is int ? sizeVal : (sizeVal is num ? sizeVal.toInt() : 0),
    );
  }
}

@immutable
class YoukoMixReleaseInfo {
  final String version;
  final String releaseUrl;
  final int updatedAt;
  final Map<String, YoukoMixReleaseAsset> assets;

  const YoukoMixReleaseInfo({
    required this.version,
    required this.releaseUrl,
    this.updatedAt = 0,
    this.assets = const {},
  });

  factory YoukoMixReleaseInfo.fromJson(Map<String, Object?> json) {
    final rawAssets = json['assets'];
    final parsedAssets = <String, YoukoMixReleaseAsset>{};
    if (rawAssets is Map) {
      for (final entry in rawAssets.entries) {
        if (entry.value is Map) {
          parsedAssets[entry.key.toString()] = YoukoMixReleaseAsset.fromJson(
            Map<String, Object?>.from(entry.value as Map),
          );
        }
      }
    }
    final updatedRaw = json['updated_at'];
    return YoukoMixReleaseInfo(
      version: json['version']?.toString() ?? '',
      releaseUrl: json['release_url']?.toString() ?? '',
      updatedAt: updatedRaw is int
          ? updatedRaw
          : (updatedRaw is num ? updatedRaw.toInt() : 0),
      assets: parsedAssets,
    );
  }
}

class YoukoMixApiClient {
  final Dio _dio;
  final YoukoMixSessionStorage _storage;
  final YoukoMixServerPublicKey? _pinnedServerKey;

  YoukoMixApiClient({
    Dio? dio,
    YoukoMixSessionStorage? storage,
    String? pinnedServerPubkey,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 12),
               receiveTimeout: const Duration(seconds: 25),
               sendTimeout: const Duration(seconds: 12),
               headers: {
                 HttpHeaders.acceptHeader: 'application/json',
                 HttpHeaders.userAgentHeader: '$appCodeName/1.1',
               },
             ),
           ),
       _storage = storage ?? youkomixStorage,
       _pinnedServerKey = _resolveInitialKey(pinnedServerPubkey);

  static YoukoMixServerPublicKey? _resolveInitialKey(String? explicitKey) {
    final raw = (explicitKey ?? defaultYoukoMixServerPubkey).trim();
    if (raw.isEmpty) {
      return null;
    }
    return YoukoMixServerPublicKey.parse(raw);
  }

  static String currentPlatformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    return Platform.operatingSystem;
  }

  static String currentDeviceName() {
    try {
      final host = Platform.localHostname.trim();
      if (host.isNotEmpty) {
        return host;
      }
    } catch (_) {}
    return '$appCodeName-${currentPlatformName()}';
  }

  Future<YoukoMixMeta> fetchMeta(String serverUrl) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _withEndpointFailover(
      base,
      (endpoint) => _requestSignedPublic(
        endpoint: endpoint,
        routeKey: '/api/v1/client/meta',
      ),
    );
    final meta = YoukoMixMeta.fromJson(data, fallbackBaseUrl: base);
    if (meta.apiEndpoints.isNotEmpty) {
      _storage.setApiEndpoints(meta.apiEndpoints, origin: base);
    }
    return meta;
  }

  Future<YoukoMixCaptchaChallenge> fetchCaptcha(String serverUrl) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestEncryptedWithFailover(
      base: base,
      routeKey: '/api/v1/client/auth/captcha',
    );
    final challenge = YoukoMixCaptchaChallenge.fromJson(data);
    if (!challenge.isValid) {
      final l10n = AppLocalizations.maybeCurrent;
      throw YoukoMixApiException(
        message: l10n?.youkomixErrFetchCaptchaFailed ?? '获取图形验证码失败，请重试',
        errorCode: 'invalid_response',
      );
    }
    return challenge;
  }

  Future<YoukoMixLoginOutcome> login({
    required String serverUrl,
    required String email,
    required String password,
    String? captchaId,
    String? captchaCode,
    String? deviceName,
    String? platform,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    try {
      final cleanCaptchaId = captchaId?.trim() ?? '';
      final cleanCaptchaCode = captchaCode?.trim() ?? '';
      final data = await _requestEncryptedWithFailover(
        base: base,
        routeKey: '/api/v1/client/auth/login',
        body: {
          'email': email.trim(),
          'password': password,
          'device_name': deviceName ?? currentDeviceName(),
          'platform': platform ?? currentPlatformName(),
          if (cleanCaptchaId.isNotEmpty) 'captcha_id': cleanCaptchaId,
          if (cleanCaptchaCode.isNotEmpty) 'captcha_code': cleanCaptchaCode,
        },
      );
      if (data['mfa_required'] == true) {
        final challenge = data['mfa_token']?.toString() ?? '';
        final expiresRaw = data['expires_in'];
        final expiresIn = expiresRaw is int
            ? expiresRaw
            : (expiresRaw is num ? expiresRaw.toInt() : 300);
        return YoukoMixLoginMfaRequired(
          challengeToken: challenge,
          expiresIn: expiresIn,
          webAuthUrl:
              data['web_auth_url']?.toString() ?? '$base/user/client-auth',
        );
      }
      final session = YoukoMixSession.fromJson(data, fallbackServerUrl: base);
      if (session.apiEndpoints.isNotEmpty) {
        _storage.setApiEndpoints(session.apiEndpoints, origin: base);
      }
      return YoukoMixLoginAuthenticated(session);
    } on YoukoMixApiException catch (error) {
      if (error.fromAuthenticatedEnvelope &&
          (error.errorCode == 'captcha_required' ||
              error.errorCode == 'captcha_invalid' ||
              error.errorCode == 'web_auth_required')) {
        final webUrl =
            error.data['web_auth_url']?.toString() ?? '$base/user/client-auth';
        final rawCaptcha = error.data['captcha'];
        final parsedChallenge = rawCaptcha is Map
            ? YoukoMixCaptchaChallenge.fromJson(
                Map<String, Object?>.from(rawCaptcha),
              )
            : null;
        return YoukoMixLoginCaptchaRequired(
          challenge: (parsedChallenge != null && parsedChallenge.isValid)
              ? parsedChallenge
              : null,
          webAuthUrl: webUrl,
          message: error.message,
        );
      }
      rethrow;
    }
  }

  Future<YoukoMixSession> verifyMfa({
    required String serverUrl,
    required String challengeToken,
    required String code,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestEncryptedWithFailover(
      base: base,
      routeKey: '/api/v1/client/auth/mfa',
      body: {'mfa_token': challengeToken.trim(), 'code': code.trim()},
    );
    final session = YoukoMixSession.fromJson(data, fallbackServerUrl: base);
    if (session.apiEndpoints.isNotEmpty) {
      _storage.setApiEndpoints(session.apiEndpoints, origin: base);
    }
    return session;
  }

  Future<YoukoMixSession> exchangeCode({
    required String serverUrl,
    required String code,
    String? deviceName,
    String? platform,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestEncryptedWithFailover(
      base: base,
      routeKey: '/api/v1/client/auth/exchange',
      body: {
        'code': code.trim(),
        'device_name': deviceName ?? currentDeviceName(),
        'platform': platform ?? currentPlatformName(),
      },
    );
    final session = YoukoMixSession.fromJson(data, fallbackServerUrl: base);
    if (session.apiEndpoints.isNotEmpty) {
      _storage.setApiEndpoints(session.apiEndpoints, origin: base);
    }
    return session;
  }

  Future<void> logout({
    required String serverUrl,
    required String accessToken,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    await _requestEncryptedWithFailover(
      base: base,
      routeKey: '/api/v1/client/auth/logout',
      accessToken: accessToken,
    );
  }

  Future<YoukoMixBootstrap> fetchBootstrap({
    required String serverUrl,
    required String accessToken,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestEncryptedWithFailover(
      base: base,
      routeKey: '/api/v1/client/bootstrap',
      accessToken: accessToken,
    );
    final bootstrap = YoukoMixBootstrap.fromJson(data);
    if (bootstrap.apiEndpoints.isNotEmpty) {
      _storage.setApiEndpoints(bootstrap.apiEndpoints, origin: base);
    }
    return bootstrap;
  }

  Future<YoukoMixCheckinResult> checkin({
    required String serverUrl,
    required String accessToken,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestEncryptedWithFailover(
      base: base,
      routeKey: '/api/v1/client/checkin',
      accessToken: accessToken,
    );
    final result = YoukoMixCheckinResult.fromJson(data);
    if (result.bootstrap.apiEndpoints.isNotEmpty) {
      _storage.setApiEndpoints(result.bootstrap.apiEndpoints, origin: base);
    }
    return result;
  }

  Future<YoukoMixSubscriptionPayload> downloadSubscription({
    required String serverUrl,
    required String accessToken,
    String mode = 'auto',
    String? userAgent,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestEncryptedWithFailover(
      base: base,
      routeKey: '/api/v1/client/subscription',
      accessToken: accessToken,
      body: {'mode': mode},
      extraHeaders: {
        if (userAgent != null && userAgent.isNotEmpty)
          HttpHeaders.userAgentHeader: userAgent,
      },
    );

    final contentB64 = data['content_b64']?.toString().trim() ?? '';
    Uint8List decodedBytes = Uint8List(0);
    if (contentB64.isNotEmpty) {
      try {
        decodedBytes = Uint8List.fromList(base64Decode(contentB64));
      } on FormatException {
        final l10n = AppLocalizations.maybeCurrent;
        throw YoukoMixApiException(
          message: l10n?.youkomixErrDecodeSubFailed ?? '订阅密文内容解码失败',
          errorCode: 'invalid_response',
        );
      }
    }
    final decompressed = decompressUnlabeled(decodedBytes);
    if (decompressed.isEmpty) {
      final l10n = AppLocalizations.maybeCurrent;
      throw YoukoMixApiException(
        message: l10n?.youkomixErrEmptySubscription ?? '返回的节点配置为空',
        errorCode: 'empty_subscription',
      );
    }

    final subMode = data['mode']?.toString().trim() ?? 'standard';
    final title = data['title']?.toString().trim() ?? '';
    final userinfo = data['userinfo']?.toString().trim();
    final intervalRaw = data['update_interval_hours'];
    final intervalHours = intervalRaw is int
        ? intervalRaw
        : (intervalRaw is num ? intervalRaw.toInt() : 6);

    return YoukoMixSubscriptionPayload(
      bytes: decompressed,
      mode: subMode.isEmpty ? 'standard' : subMode,
      title: title.isEmpty ? appName : title,
      userInfoHeader: (userinfo != null && userinfo.isNotEmpty)
          ? userinfo
          : null,
      updateIntervalHours: intervalHours > 0 ? intervalHours : 6,
    );
  }

  Future<YoukoMixReleaseInfo> fetchRelease(String serverUrl) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _withEndpointFailover(
      base,
      (endpoint) => _requestSignedPublic(
        endpoint: endpoint,
        routeKey: '/api/v1/client/release',
      ),
    );
    return YoukoMixReleaseInfo.fromJson(data);
  }

  YoukoMixServerPublicKey _requirePinnedServerKey() {
    final pinned = _pinnedServerKey;
    if (pinned == null) {
      final msg = AppLocalizations.maybeCurrent?.youkomixErrMissingServerPubkey;
      throw YoukoMixApiException(
        message: msg ?? '客户端未配置预置安全公钥，已拒绝建立安全信道',
        errorCode: 'missing_server_pubkey',
      );
    }
    return pinned;
  }

  Future<Map<String, Object?>> _requestEncryptedWithFailover({
    required String base,
    required String routeKey,
    Map<String, Object?>? body,
    String? accessToken,
    Map<String, String>? extraHeaders,
  }) async {
    final serverKey = _requirePinnedServerKey();
    return _withEndpointFailover(
      base,
      (endpoint) => _requestEncryptedSingle(
        endpoint: endpoint,
        routeKey: routeKey,
        serverKey: serverKey,
        body: body,
        accessToken: accessToken,
        extraHeaders: extraHeaders,
      ),
    );
  }

  Future<T> _withEndpointFailover<T>(
    String base,
    Future<T> Function(String endpoint) operation,
  ) async {
    await _storage.ensureEndpointsLoaded(base);
    final candidates = _storage.candidateEndpoints(base);
    final targets = candidates.isNotEmpty ? candidates : <String>[base];
    YoukoMixApiException? lastError;

    for (var i = 0; i < targets.length; i++) {
      final endpoint = targets[i];
      try {
        final result = await operation(endpoint);
        _storage.promoteEndpoint(endpoint, origin: base);
        return result;
      } on YoukoMixApiException catch (error) {
        lastError = error;
        final hasMore = i + 1 < targets.length;
        if (!hasMore || !_shouldFailover(error)) {
          rethrow;
        }
      }
    }

    final msg = AppLocalizations.maybeCurrent?.youkomixErrNetworkUnreachable;
    throw lastError ??
        YoukoMixApiException(
          message: msg ?? '无法连接面板服务器，请检查网络或面板地址',
          errorCode: 'network_error',
        );
  }

  bool _shouldFailover(YoukoMixApiException error) {
    if (error.fromAuthenticatedEnvelope || error.isUpgradeRequired) {
      return false;
    }
    return switch (error.errorCode) {
      'clock_skew' ||
      'missing_server_pubkey' ||
      'invalid_server_pubkey' ||
      'invalid_server_url' => false,
      _ => true,
    };
  }

  Future<Map<String, Object?>> _requestSignedPublic({
    required String endpoint,
    required String routeKey,
  }) async {
    final serverKey = _requirePinnedServerKey();
    final jsonMap = await _sendRawHttpJson(
      method: 'GET',
      url: '$endpoint$routeKey',
    );
    final verified = await YoukoMixCrypto.verifyPublicResponse(
      routeKey: routeKey,
      json: jsonMap,
      pinnedKey: serverKey,
    );
    return verified.data;
  }

  Future<Map<String, Object?>> _requestEncryptedSingle({
    required String endpoint,
    required String routeKey,
    required YoukoMixServerPublicKey serverKey,
    Map<String, Object?>? body,
    String? accessToken,
    Map<String, String>? extraHeaders,
  }) async {
    final sealed = await YoukoMixCrypto.sealRequest(
      routeKey: routeKey,
      serverKey: serverKey,
      payload: body,
      accessToken: accessToken,
    );
    final outerJson = await _sendRawHttpJson(
      method: 'POST',
      url: '$endpoint$routeKey',
      body: sealed.envelope,
      extraHeaders: extraHeaders,
      expectEncryptedEnvelope: true,
    );
    final inner = await YoukoMixCrypto.openResponse(
      request: sealed,
      envelope: outerJson,
    );

    final ret = inner['ret'];
    final ok = ret == 1 || ret == true || ret == '1';
    if (!ok) {
      final statusRaw = inner['http_status'];
      final innerStatus = statusRaw is int
          ? statusRaw
          : (statusRaw is num ? statusRaw.toInt() : 400);
      final payload = inner['data'];
      final l10n = AppLocalizations.maybeCurrent;
      final reqFailed = l10n?.youkomixErrRequestFailed ?? '请求失败';
      throw YoukoMixApiException(
        message: inner['msg']?.toString() ?? '$reqFailed ($innerStatus)',
        errorCode: inner['code']?.toString() ?? 'api_error',
        statusCode: innerStatus,
        data: payload is Map ? Map<String, Object?>.from(payload) : const {},
        fromAuthenticatedEnvelope: true,
      );
    }

    final data = inner['data'];
    if (data is Map) {
      return Map<String, Object?>.from(data);
    }
    return const {};
  }

  Future<Map<String, Object?>> _sendRawHttpJson({
    required String method,
    required String url,
    Map<String, Object?>? body,
    Map<String, String>? extraHeaders,
    bool expectEncryptedEnvelope = false,
  }) async {
    try {
      final mergedHeaders = <String, String>{
        HttpHeaders.acceptLanguageHeader: _activeAcceptLanguageTag(),
        if (extraHeaders != null) ...extraHeaders,
      };
      final response = await _dio.request<Object?>(
        url,
        data: body,
        options: Options(
          method: method,
          responseType: ResponseType.plain,
          contentType: body != null ? Headers.jsonContentType : null,
          validateStatus: (_) => true,
          headers: mergedHeaders,
        ),
      );
      final status = response.statusCode ?? 0;
      final jsonMap = _decodeJsonMap(response.data);
      final l10n = AppLocalizations.maybeCurrent;
      final reqFailed = l10n?.youkomixErrRequestFailed ?? '请求失败';
      if (jsonMap == null) {
        final unavailable = l10n?.youkomixErrServerUnavailable ?? '面板服务暂时不可用';
        final unparseable = l10n?.youkomixErrInvalidResponse ?? '无法解析面板响应';
        final errLabel = status >= 500 ? unavailable : unparseable;
        throw YoukoMixApiException(
          message: '$errLabel ($status)',
          errorCode: 'invalid_response',
          statusCode: status,
        );
      }

      if (status < 200 || status >= 300) {
        final rawCode = jsonMap['code']?.toString() ?? '';
        final safeCode = switch (rawCode) {
          'client_upgrade_required' ||
          'clock_skew' ||
          'rate_limited' => rawCode,
          _ => 'proxy_http_error',
        };
        final payload = jsonMap['data'];
        throw YoukoMixApiException(
          message: jsonMap['msg']?.toString() ?? '$reqFailed ($status)',
          errorCode: safeCode,
          statusCode: status,
          data: payload is Map ? Map<String, Object?>.from(payload) : const {},
        );
      }

      if (!expectEncryptedEnvelope) {
        final ret = jsonMap['ret'];
        final ok = ret == 1 || ret == true || ret == '1';
        if (!ok) {
          final payload = jsonMap['data'];
          throw YoukoMixApiException(
            message: jsonMap['msg']?.toString() ?? '$reqFailed ($status)',
            errorCode: jsonMap['code']?.toString() ?? 'api_error',
            statusCode: status,
            data: payload is Map
                ? Map<String, Object?>.from(payload)
                : const {},
          );
        }
      }

      return jsonMap;
    } on YoukoMixApiException {
      rethrow;
    } on DioException catch (error) {
      throw _fromDioException(error);
    }
  }

  Map<String, Object?>? _decodeJsonMap(Object? rawData) {
    if (rawData is Map) {
      return Map<String, Object?>.from(rawData);
    }
    final rawText = switch (rawData) {
      final String text => text,
      final List<int> bytes => utf8.decode(bytes, allowMalformed: true),
      _ => rawData?.toString() ?? '',
    };
    if (rawText.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _activeAcceptLanguageTag() {
    final raw = (Intl.defaultLocale ?? '').trim();
    return switch (raw) {
      'zh_TW' => 'zh-TW',
      'en' => 'en-US',
      'ja' => 'ja-JP',
      'ko' => 'ko-KR',
      'ru' => 'ru-RU',
      'es' => 'es-ES',
      'fr' => 'fr-FR',
      _ => 'zh-CN',
    };
  }

  YoukoMixApiException _fromDioException(DioException error) {
    final l10n = AppLocalizations.maybeCurrent;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => YoukoMixApiException(
        message: l10n?.youkomixErrNetworkTimeout ?? '连接面板超时，请检查网络后重试',
        errorCode: 'network_timeout',
      ),
      DioExceptionType.badCertificate => YoukoMixApiException(
        message: l10n?.youkomixErrBadCertificate ?? '面板安全证书校验失败',
        errorCode: 'bad_certificate',
      ),
      _ => YoukoMixApiException(
        message: l10n?.youkomixErrNetworkUnreachable ?? '无法连接面板服务器，请检查网络或面板地址',
        errorCode: 'network_error',
      ),
    };
  }
}

final youkomixApi = YoukoMixApiClient();
