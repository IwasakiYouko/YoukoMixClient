import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/youkomix_api.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Handler =
    ResponseBody Function(RequestOptions options, String bodyText);

class _FakeAdapter implements HttpClientAdapter {
  final _Handler handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
    }
    return handler(options, utf8.decode(chunks, allowMalformed: true));
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Map<String, Object?> payload, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(payload),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('normalizeYoukoMixServerUrl', () {
    test('normalizes bare domains and strips trailing slashes', () {
      expect(
        normalizeYoukoMixServerUrl('panel.example.com///'),
        'https://panel.example.com',
      );
      expect(
        normalizeYoukoMixServerUrl('https://sub.example.com:8443/base/'),
        'https://sub.example.com:8443/base',
      );
    });

    test('rejects empty, non-http, or credential-bearing URLs', () {
      expect(
        () => normalizeYoukoMixServerUrl('  '),
        throwsA(isA<YoukoMixApiException>()),
      );
      expect(
        () => normalizeYoukoMixServerUrl('ftp://example.com'),
        throwsA(isA<YoukoMixApiException>()),
      );
      expect(
        () => normalizeYoukoMixServerUrl('https://user:pass@example.com'),
        throwsA(isA<YoukoMixApiException>()),
      );
    });
  });

  group('YoukoMixApiClient', () {
    YoukoMixApiClient clientWith(_Handler handler) {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(handler);
      return YoukoMixApiClient(dio: dio);
    }

    test('fetchMeta parses server meta envelope', () async {
      final client = clientWith((options, _) {
        expect(options.uri.path, '/api/v1/client/meta');
        return _jsonBody({
          'ret': 1,
          'data': {
            'app_name': '人间之里',
            'login_captcha_enabled': false,
            'web_auth_url': 'https://panel.example.com/user/client-auth',
          },
        });
      });

      final meta = await client.fetchMeta('panel.example.com');
      expect(meta.appName, '人间之里');
      expect(meta.baseUrl, 'https://panel.example.com');
    });

    test(
      'login handles direct auth, MFA challenge, and CAPTCHA handoff',
      () async {
        var mode = 'direct';
        final client = clientWith((options, bodyText) {
          expect(options.method, 'POST');
          expect(options.uri.path, '/api/v1/client/auth/login');
          final decoded = jsonDecode(bodyText) as Map<String, Object?>;
          expect(decoded['email'], 'reimu@example.com');

          if (mode == 'direct') {
            return _jsonBody({
              'ret': 1,
              'data': {
                'mfa_required': false,
                'token': 'ymx_direct',
                'expires_at': 1999999999,
                'bootstrap': {
                  'user': {'id': 1, 'user_name': '灵梦'},
                },
              },
            });
          }
          if (mode == 'mfa') {
            return _jsonBody({
              'ret': 1,
              'data': {
                'mfa_required': true,
                'mfa_token': 'mfa_tok_123',
                'expires_in': 300,
              },
            });
          }
          return _jsonBody({
            'ret': 0,
            'code': 'captcha_required',
            'msg': '请完成人机验证',
            'data': {
              'web_auth_url': 'https://panel.example.com/user/client-auth',
            },
          }, status: 403);
        });

        final direct = await client.login(
          serverUrl: 'https://panel.example.com',
          email: ' reimu@example.com ',
          password: 'secret',
        );
        expect(direct, isA<YoukoMixLoginAuthenticated>());
        expect(
          (direct as YoukoMixLoginAuthenticated).session.accessToken,
          'ymx_direct',
        );

        mode = 'mfa';
        final mfa = await client.login(
          serverUrl: 'https://panel.example.com',
          email: 'reimu@example.com',
          password: 'secret',
        );
        expect(mfa, isA<YoukoMixLoginMfaRequired>());
        expect((mfa as YoukoMixLoginMfaRequired).challengeToken, 'mfa_tok_123');

        mode = 'captcha';
        final captcha = await client.login(
          serverUrl: 'https://panel.example.com',
          email: 'reimu@example.com',
          password: 'secret',
        );
        expect(captcha, isA<YoukoMixLoginCaptchaRequired>());
        expect(
          (captcha as YoukoMixLoginCaptchaRequired).webAuthUrl,
          'https://panel.example.com/user/client-auth',
        );
      },
    );

    test(
      'verifyMfa, exchangeCode, fetchBootstrap, fetchRelease, logout',
      () async {
        final seenPaths = <String>[];
        final client = clientWith((options, _) {
          seenPaths.add(options.uri.path);
          switch (options.uri.path) {
            case '/api/v1/client/auth/mfa':
            case '/api/v1/client/auth/exchange':
              return _jsonBody({
                'ret': 1,
                'data': {'token': 'ymx_tok', 'expires_at': 1999999999},
              });
            case '/api/v1/client/bootstrap':
              return _jsonBody({
                'ret': 1,
                'data': {
                  'user': {'id': 2, 'email': 'marisa@example.com'},
                },
              });
            case '/api/v1/client/release':
              return _jsonBody({
                'ret': 1,
                'data': {
                  'version': '1.2.0',
                  'release_url': 'https://panel.example.com/download',
                  'assets': {
                    'YoukoMix-1.2.0-linux-amd64.deb': {
                      'url': 'https://panel.example.com/pkg.deb',
                      'sha256': 'ABCDEF',
                      'size': 1024,
                    },
                  },
                },
              });
            case '/api/v1/client/auth/logout':
              return _jsonBody({'ret': 1, 'data': const <String, Object?>{}});
          }
          return _jsonBody({'ret': 0, 'msg': 'not found'}, status: 404);
        });

        final mfaSession = await client.verifyMfa(
          serverUrl: 'https://panel.example.com',
          challengeToken: 'mfa_1',
          code: '123456',
        );
        expect(mfaSession.accessToken, 'ymx_tok');

        final exchanged = await client.exchangeCode(
          serverUrl: 'https://panel.example.com',
          code: 'ymxc_abc',
        );
        expect(exchanged.accessToken, 'ymx_tok');

        final bootstrap = await client.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_tok',
        );
        expect(bootstrap.user.email, 'marisa@example.com');

        final release = await client.fetchRelease('https://panel.example.com');
        expect(release.version, '1.2.0');
        expect(
          release.assets['YoukoMix-1.2.0-linux-amd64.deb']?.sha256,
          'abcdef',
        );

        await client.logout(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_tok',
        );
        expect(seenPaths, hasLength(5));
      },
    );

    test(
      'downloadSubscription decompresses gzip YAML and parses headers',
      () async {
        final yamlBytes = utf8.encode('proxies:\n  - {name: HK, type: ss}\n');
        final compressed = gzip.encode(yamlBytes);
        final client = clientWith((options, _) {
          expect(options.uri.path, '/api/v1/client/subscription');
          expect(options.uri.queryParameters['mode'], 'auto');
          expect(
            options.headers[HttpHeaders.authorizationHeader],
            'Bearer ymx_sub_tok',
          );
          return ResponseBody.fromBytes(
            compressed,
            200,
            headers: {
              'x-youkomix-sub-mode': ['exclusive'],
              'content-disposition': [
                "attachment; filename*=UTF-8''YoukoMix.yaml",
              ],
              'subscription-userinfo': ['upload=10; download=20; total=100'],
              'profile-update-interval': ['8'],
            },
          );
        });

        final payload = await client.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ymx_sub_tok',
          userAgent: 'YoukoMix/1.0',
        );
        expect(utf8.decode(payload.bytes), contains('name: HK'));
        expect(payload.mode, 'exclusive');
        expect(payload.title, 'YoukoMix.yaml');
        expect(payload.updateIntervalHours, 8);
        expect(payload.userInfoHeader, contains('total=100'));
      },
    );

    test(
      'downloadSubscription surfaces JSON error when status is 401',
      () async {
        final client = clientWith((_, _) {
          return ResponseBody.fromBytes(
            utf8.encode(
              jsonEncode({'ret': 0, 'code': 'unauthorized', 'msg': '登录已过期'}),
            ),
            401,
          );
        });

        await expectLater(
          client.downloadSubscription(
            serverUrl: 'https://panel.example.com',
            accessToken: 'expired_tok',
          ),
          throwsA(
            isA<YoukoMixApiException>().having(
              (e) => e.isSessionInvalid,
              'isSessionInvalid',
              isTrue,
            ),
          ),
        );
      },
    );
  });
}
