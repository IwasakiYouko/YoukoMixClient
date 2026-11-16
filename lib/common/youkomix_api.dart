import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:flutter/foundation.dart';

import 'constant.dart';
import 'request.dart';

String normalizeYoukoMixServerUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const YoukoMixApiException(
      message: '请输入面板地址',
      errorCode: 'invalid_server_url',
    );
  }
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(withScheme);
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw const YoukoMixApiException(
      message: '面板地址格式无效，请使用 https:// 域名',
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

  const YoukoMixApiException({
    required this.message,
    this.errorCode = 'api_error',
    this.statusCode,
    this.data = const {},
  });

  bool get isUnauthorized =>
      statusCode == 401 &&
      (errorCode == 'unauthorized' ||
          errorCode == 'exchange_expired' ||
          errorCode == 'mfa_expired');

  bool get isSessionInvalid => statusCode == 401 && errorCode == 'unauthorized';

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

  YoukoMixApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
              sendTimeout: const Duration(seconds: 15),
              headers: {
                HttpHeaders.acceptHeader: 'application/json',
                HttpHeaders.userAgentHeader: '$appCodeName/1.0',
              },
            ),
          );

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
    final data = await _requestJson(
      method: 'GET',
      url: '$base/api/v1/client/meta',
    );
    return YoukoMixMeta.fromJson(data, fallbackBaseUrl: base);
  }

  Future<YoukoMixLoginOutcome> login({
    required String serverUrl,
    required String email,
    required String password,
    String? deviceName,
    String? platform,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    try {
      final data = await _requestJson(
        method: 'POST',
        url: '$base/api/v1/client/auth/login',
        body: {
          'email': email.trim(),
          'password': password,
          'device_name': deviceName ?? currentDeviceName(),
          'platform': platform ?? currentPlatformName(),
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
      return YoukoMixLoginAuthenticated(
        YoukoMixSession.fromJson(data, fallbackServerUrl: base),
      );
    } on YoukoMixApiException catch (error) {
      if (error.errorCode == 'captcha_required' ||
          error.errorCode == 'web_auth_required') {
        final webUrl =
            error.data['web_auth_url']?.toString() ?? '$base/user/client-auth';
        return YoukoMixLoginCaptchaRequired(
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
    final data = await _requestJson(
      method: 'POST',
      url: '$base/api/v1/client/auth/mfa',
      body: {'mfa_token': challengeToken.trim(), 'code': code.trim()},
    );
    return YoukoMixSession.fromJson(data, fallbackServerUrl: base);
  }

  Future<YoukoMixSession> exchangeCode({
    required String serverUrl,
    required String code,
    String? deviceName,
    String? platform,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestJson(
      method: 'POST',
      url: '$base/api/v1/client/auth/exchange',
      body: {
        'code': code.trim(),
        'device_name': deviceName ?? currentDeviceName(),
        'platform': platform ?? currentPlatformName(),
      },
    );
    return YoukoMixSession.fromJson(data, fallbackServerUrl: base);
  }

  Future<void> logout({
    required String serverUrl,
    required String accessToken,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    await _requestJson(
      method: 'POST',
      url: '$base/api/v1/client/auth/logout',
      accessToken: accessToken,
    );
  }

  Future<YoukoMixBootstrap> fetchBootstrap({
    required String serverUrl,
    required String accessToken,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestJson(
      method: 'GET',
      url: '$base/api/v1/client/bootstrap',
      accessToken: accessToken,
    );
    return YoukoMixBootstrap.fromJson(data);
  }

  Future<YoukoMixSubscriptionPayload> downloadSubscription({
    required String serverUrl,
    required String accessToken,
    String mode = 'auto',
    String? userAgent,
  }) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final uri = Uri.parse(
      '$base/api/v1/client/subscription',
    ).replace(queryParameters: {'mode': mode});
    try {
      final response = await _dio.getUri<List<int>>(
        uri,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (_) => true,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            HttpHeaders.acceptHeader: 'application/yaml, text/plain, */*',
            if (userAgent != null && userAgent.isNotEmpty)
              HttpHeaders.userAgentHeader: userAgent,
          },
        ),
      );
      final status = response.statusCode ?? 0;
      final rawBytes = Uint8List.fromList(response.data ?? const <int>[]);
      final decompressed = decompressUnlabeled(rawBytes);
      if (status < 200 || status >= 300) {
        throw _parseBytesError(decompressed, status);
      }
      if (decompressed.isEmpty) {
        throw const YoukoMixApiException(
          message: '返回的节点配置为空',
          errorCode: 'empty_subscription',
        );
      }
      final subMode =
          response.headers.value('x-youkomix-sub-mode')?.trim() ?? 'standard';
      final disposition = response.headers.value('content-disposition');
      final title = getFileNameForDisposition(disposition)?.trim();
      final intervalRaw = response.headers.value('profile-update-interval');
      final intervalHours = int.tryParse(intervalRaw ?? '') ?? 6;
      return YoukoMixSubscriptionPayload(
        bytes: decompressed,
        mode: subMode.isEmpty ? 'standard' : subMode,
        title: (title == null || title.isEmpty) ? appName : title,
        userInfoHeader: response.headers.value('subscription-userinfo'),
        updateIntervalHours: intervalHours > 0 ? intervalHours : 6,
      );
    } on YoukoMixApiException {
      rethrow;
    } on DioException catch (error) {
      throw _fromDioException(error);
    }
  }

  Future<YoukoMixReleaseInfo> fetchRelease(String serverUrl) async {
    final base = normalizeYoukoMixServerUrl(serverUrl);
    final data = await _requestJson(
      method: 'GET',
      url: '$base/api/v1/client/release',
    );
    return YoukoMixReleaseInfo.fromJson(data);
  }

  Future<Map<String, Object?>> _requestJson({
    required String method,
    required String url,
    Map<String, Object?>? body,
    String? accessToken,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        url,
        data: body,
        options: Options(
          method: method,
          responseType: ResponseType.plain,
          contentType: body != null ? Headers.jsonContentType : null,
          validateStatus: (_) => true,
          headers: {
            if (accessToken != null && accessToken.isNotEmpty)
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
        ),
      );
      final status = response.statusCode ?? 0;
      Map<String, Object?>? jsonMap;
      final rawData = response.data;
      if (rawData is Map) {
        jsonMap = Map<String, Object?>.from(rawData);
      } else {
        final rawText = switch (rawData) {
          final String text => text,
          final List<int> bytes => utf8.decode(bytes, allowMalformed: true),
          _ => rawData?.toString() ?? '',
        };
        if (rawText.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawText);
            if (decoded is Map) {
              jsonMap = Map<String, Object?>.from(decoded);
            }
          } on FormatException {
            jsonMap = null;
          }
        }
      }
      if (jsonMap == null) {
        throw YoukoMixApiException(
          message: status >= 500 ? '面板服务暂时不可用 ($status)' : '无法解析面板响应 ($status)',
          errorCode: 'invalid_response',
          statusCode: status,
        );
      }
      final ret = jsonMap['ret'];
      final ok =
          status >= 200 &&
          status < 300 &&
          (ret == 1 || ret == true || ret == '1');
      if (!ok) {
        final payload = jsonMap['data'];
        throw YoukoMixApiException(
          message: jsonMap['msg']?.toString() ?? '请求失败 ($status)',
          errorCode: jsonMap['code']?.toString() ?? 'api_error',
          statusCode: status,
          data: payload is Map ? Map<String, Object?>.from(payload) : const {},
        );
      }
      final data = jsonMap['data'];
      if (data is Map) {
        return Map<String, Object?>.from(data);
      }
      return const {};
    } on YoukoMixApiException {
      rethrow;
    } on DioException catch (error) {
      throw _fromDioException(error);
    }
  }

  YoukoMixApiException _parseBytesError(Uint8List bytes, int status) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      if (decoded is Map) {
        final map = Map<String, Object?>.from(decoded);
        final payload = map['data'];
        return YoukoMixApiException(
          message: map['msg']?.toString() ?? '订阅同步失败 ($status)',
          errorCode: map['code']?.toString() ?? 'subscription_error',
          statusCode: status,
          data: payload is Map ? Map<String, Object?>.from(payload) : const {},
        );
      }
    } on FormatException {
      return YoukoMixApiException(
        message: '订阅同步失败 ($status)',
        errorCode: 'subscription_error',
        statusCode: status,
      );
    }
    return YoukoMixApiException(
      message: '订阅同步失败 ($status)',
      errorCode: 'subscription_error',
      statusCode: status,
    );
  }

  YoukoMixApiException _fromDioException(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const YoukoMixApiException(
        message: '连接面板超时，请检查网络后重试',
        errorCode: 'network_timeout',
      ),
      DioExceptionType.badCertificate => const YoukoMixApiException(
        message: '面板安全证书校验失败',
        errorCode: 'bad_certificate',
      ),
      _ => const YoukoMixApiException(
        message: '无法连接面板服务器，请检查网络或面板地址',
        errorCode: 'network_error',
      ),
    };
  }
}

final youkomixApi = YoukoMixApiClient();
