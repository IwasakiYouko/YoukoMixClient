import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fl_clash/common/youkomix_api.dart';
import 'package:fl_clash/common/youkomix_storage.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/youkomix_e2ee_server.dart';

typedef _AsyncHandler =
    Future<ResponseBody> Function(RequestOptions options, String bodyText);

class _FakeAdapter implements HttpClientAdapter {
  final _AsyncHandler handler;

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
  late Directory tempDir;
  late YoukoMixSessionStorage storage;
  late FakeYoukoMixE2eeServer server;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('youkomix-api-test-');
    storage = YoukoMixSessionStorage(homeDirProvider: () async => tempDir.path);
    server = await FakeYoukoMixE2eeServer.create();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

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

  group('YoukoMixApiClient (E2EE + Ed25519 + Failover)', () {
    YoukoMixApiClient clientWith(_AsyncHandler handler, {String? pinnedKey}) {
      final dio = Dio()..httpClientAdapter = _FakeAdapter(handler);
      return YoukoMixApiClient(
        dio: dio,
        storage: storage,
        pinnedServerPubkey: pinnedKey ?? server.pubkeyToken,
      );
    }

    test(
      'fetchMeta verifies Ed25519 signature and populates acceleration endpoints',
      () async {
        final client = clientWith((options, _) async {
          expect(options.uri.path, '/api/v1/client/meta');
          return _jsonBody(
            await server.signPublicData('/api/v1/client/meta', {
              'app_name': '人间之里',
              'api_endpoints': [
                'https://edge1.example.com/',
                'https://panel.example.com/',
              ],
              'download_base_url': 'https://dl.example.com/',
              'login_captcha_enabled': true,
              'captcha_mode': 'native_image',
              'min_client_version': '1.1.0',
              'e2ee_required': true,
            }),
          );
        });

        final meta = await client.fetchMeta('panel.example.com');
        expect(meta.appName, '人间之里');
        expect(meta.baseUrl, 'https://panel.example.com');
        expect(meta.downloadBaseUrl, 'https://dl.example.com');
        expect(meta.apiEndpoints, [
          'https://edge1.example.com',
          'https://panel.example.com',
        ]);
        expect(meta.captchaEnabled, isTrue);
        expect(meta.e2eeRequired, isTrue);
        expect(storage.endpointsForOrigin('https://panel.example.com'), [
          'https://edge1.example.com',
          'https://panel.example.com',
        ]);
      },
    );

    test(
      'fetchCaptcha and login encrypt credentials, native CAPTCHA, and MFA challenges',
      () async {
        var mode = 'captcha_needed';
        final client = clientWith((options, bodyText) async {
          final envelope = jsonDecode(bodyText) as Map<String, Object?>;
          expect(envelope['v'], 1);
          // Credentials must never appear in cleartext wire JSON.
          expect(bodyText, isNot(contains('reimu@example.com')));
          expect(bodyText, isNot(contains('secret-pass')));

          if (options.uri.path == '/api/v1/client/auth/captcha') {
            final opened = await server.openEnvelope(
              '/api/v1/client/auth/captcha',
              envelope,
            );
            return _jsonBody(
              await opened.seal({
                'ret': 1,
                'http_status': 200,
                'data': {
                  'captcha_id': 'cch_fresh_1',
                  'image_base64': tinyValidPngBase64,
                  'expires_in': 180,
                },
              }),
            );
          }

          final opened = await server.openEnvelope(
            '/api/v1/client/auth/login',
            envelope,
          );
          expect(opened.payload['email'], 'reimu@example.com');
          expect(opened.payload['password'], 'secret-pass');

          if (mode == 'captcha_needed') {
            return _jsonBody(
              await opened.seal({
                'ret': 0,
                'http_status': 403,
                'code': 'captcha_required',
                'msg': '请输入图形验证码完成登录',
                'data': {
                  'captcha_required': true,
                  'captcha': {
                    'captcha_id': 'cch_inline_99',
                    'image_base64': tinyValidPngBase64,
                    'expires_in': 180,
                  },
                  'web_auth_url': 'https://panel.example.com/user/client-auth',
                },
              }),
            );
          }
          if (mode == 'mfa') {
            return _jsonBody(
              await opened.seal({
                'ret': 1,
                'http_status': 200,
                'data': {
                  'mfa_required': true,
                  'mfa_token': 'ykm_tok_123',
                  'expires_in': 300,
                },
              }),
            );
          }
          expect(opened.payload['captcha_id'], 'cch_inline_99');
          expect(opened.payload['captcha_code'], 'A7K9P');
          return _jsonBody(
            await opened.seal({
              'ret': 1,
              'http_status': 200,
              'data': {
                'mfa_required': false,
                'token': 'ykc_direct_ok',
                'expires_at': 1999999999,
                'bootstrap': {
                  'user': {'id': 1, 'user_name': '灵梦'},
                },
              },
            }),
          );
        });

        final issuedCaptcha = await client.fetchCaptcha(
          'https://panel.example.com',
        );
        expect(issuedCaptcha.captchaId, 'cch_fresh_1');
        expect(issuedCaptcha.isValid, isTrue);

        final capReq = await client.login(
          serverUrl: 'https://panel.example.com',
          email: ' reimu@example.com ',
          password: 'secret-pass',
        );
        expect(capReq, isA<YoukoMixLoginCaptchaRequired>());
        final inlineCap = (capReq as YoukoMixLoginCaptchaRequired).challenge;
        expect(inlineCap, isNotNull);
        expect(inlineCap!.captchaId, 'cch_inline_99');

        mode = 'direct';
        final authed = await client.login(
          serverUrl: 'https://panel.example.com',
          email: 'reimu@example.com',
          password: 'secret-pass',
          captchaId: inlineCap.captchaId,
          captchaCode: 'A7K9P',
        );
        expect(authed, isA<YoukoMixLoginAuthenticated>());
        expect(
          (authed as YoukoMixLoginAuthenticated).session.accessToken,
          'ykc_direct_ok',
        );

        mode = 'mfa';
        final mfa = await client.login(
          serverUrl: 'https://panel.example.com',
          email: 'reimu@example.com',
          password: 'secret-pass',
        );
        expect(mfa, isA<YoukoMixLoginMfaRequired>());
        expect((mfa as YoukoMixLoginMfaRequired).challengeToken, 'ykm_tok_123');
      },
    );

    test(
      'verifyMfa, exchangeCode, fetchBootstrap, downloadSubscription, fetchRelease, logout',
      () async {
        final yamlBytes = utf8.encode('proxies:\n  - {name: HK, type: ss}\n');
        final compressedB64 = base64Encode(gzip.encode(yamlBytes));
        final seenPaths = <String>[];

        final client = clientWith((options, bodyText) async {
          seenPaths.add(options.uri.path);
          if (options.uri.path == '/api/v1/client/release') {
            return _jsonBody(
              await server.signPublicData('/api/v1/client/release', {
                'version': 'v1.1.0',
                'release_url': 'https://dl.example.com/user',
                'assets': {
                  'YoukoMix.apk': {
                    'url': 'https://dl.example.com/clients/YoukoMix.apk',
                    'sha256': 'ABCDEF',
                    'size': 2048,
                  },
                },
              }),
            );
          }

          final envelope = jsonDecode(bodyText) as Map<String, Object?>;
          final opened = await server.openEnvelope(options.uri.path, envelope);

          switch (options.uri.path) {
            case '/api/v1/client/auth/mfa':
            case '/api/v1/client/auth/exchange':
              return _jsonBody(
                await opened.seal({
                  'ret': 1,
                  'http_status': 200,
                  'data': {'token': 'ykc_tok', 'expires_at': 1999999999},
                }),
              );
            case '/api/v1/client/bootstrap':
              expect(opened.token, 'ykc_tok');
              return _jsonBody(
                await opened.seal({
                  'ret': 1,
                  'http_status': 200,
                  'data': {
                    'panel': {
                      'base_url': 'https://panel.example.com',
                      'api_endpoints': ['https://edge-fast.example.com'],
                    },
                    'user': {'id': 2, 'email': 'marisa@example.com'},
                  },
                }),
              );
            case '/api/v1/client/subscription':
              expect(opened.token, 'ykc_tok');
              expect(opened.payload['mode'], 'exclusive');
              return _jsonBody(
                await opened.seal({
                  'ret': 1,
                  'http_status': 200,
                  'data': {
                    'content_b64': compressedB64,
                    'mode': 'exclusive',
                    'title': '人间之里 · 专属订阅',
                    'userinfo': 'upload=10; download=20; total=100',
                    'update_interval_hours': 8,
                  },
                }),
              );
            case '/api/v1/client/checkin':
              expect(opened.token, 'ykc_tok');
              return _jsonBody(
                await opened.seal({
                  'ret': 1,
                  'http_status': 200,
                  'data': {
                    'traffic_mb': 256,
                    'message': '签到成功，获得 256 MB 流量',
                    'bootstrap': {
                      'user': {'id': 2, 'email': 'marisa@example.com'},
                      'features': {
                        'checkin_enabled': true,
                        'able_to_checkin': false,
                      },
                    },
                  },
                }),
              );
            case '/api/v1/client/auth/logout':
              return _jsonBody(
                await opened.seal({
                  'ret': 1,
                  'http_status': 200,
                  'data': {'logged_out': true},
                }),
              );
          }
          return _jsonBody({'ret': 0, 'msg': 'not found'}, status: 404);
        });

        final mfaSession = await client.verifyMfa(
          serverUrl: 'https://panel.example.com',
          challengeToken: 'ykm_1',
          code: '123456',
        );
        expect(mfaSession.accessToken, 'ykc_tok');

        final exchanged = await client.exchangeCode(
          serverUrl: 'https://panel.example.com',
          code: 'ykx_abc',
        );
        expect(exchanged.accessToken, 'ykc_tok');

        final bootstrap = await client.fetchBootstrap(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ykc_tok',
        );
        expect(bootstrap.user.email, 'marisa@example.com');
        expect(storage.endpointsForOrigin('https://panel.example.com'), [
          'https://edge-fast.example.com',
        ]);

        final sub = await client.downloadSubscription(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ykc_tok',
          mode: 'exclusive',
          userAgent: 'YoukoMix/1.1',
        );
        expect(utf8.decode(sub.bytes), contains('name: HK'));
        expect(sub.mode, 'exclusive');
        expect(sub.title, '人间之里 · 专属订阅');
        expect(sub.updateIntervalHours, 8);
        expect(sub.userInfoHeader, contains('total=100'));

        final release = await client.fetchRelease('https://panel.example.com');
        expect(release.version, 'v1.1.0');
        expect(release.assets['YoukoMix.apk']?.sha256, 'abcdef');

        final checkinRes = await client.checkin(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ykc_tok',
        );
        expect(checkinRes.trafficMb, 256);
        expect(checkinRes.bootstrap.features.ableToCheckin, isFalse);

        await client.logout(
          serverUrl: 'https://panel.example.com',
          accessToken: 'ykc_tok',
        );
        expect(seenPaths, hasLength(7));
      },
    );

    test(
      'fails over automatically across broken or tampering reverse proxies and promotes healthy endpoint',
      () async {
        final rogueServer = await FakeYoukoMixE2eeServer.create(0x99);
        storage.setActiveServerUrl('https://origin.example.com');
        storage.setApiEndpoints(const [
          'https://dead-edge.example.com',
          'https://rogue-edge.example.com',
          'https://good-edge.example.com',
          'https://origin.example.com',
        ]);

        final attemptedHosts = <String>[];
        final client = clientWith((options, bodyText) async {
          attemptedHosts.add(options.uri.host);
          if (options.uri.host == 'dead-edge.example.com') {
            return ResponseBody.fromString('<html>502 Bad Gateway</html>', 502);
          }
          if (options.uri.host == 'rogue-edge.example.com') {
            // MITM proxy tries to forge response with its own Ed25519 key!
            return _jsonBody(
              await rogueServer.signPublicData('/api/v1/client/meta', {
                'app_name': '钓鱼伪造站点',
              }),
            );
          }
          return _jsonBody(
            await server.signPublicData('/api/v1/client/meta', {
              'app_name': '人间之里',
            }),
          );
        });

        final meta = await client.fetchMeta('https://origin.example.com');
        expect(meta.appName, '人间之里');
        expect(attemptedHosts, [
          'dead-edge.example.com',
          'rogue-edge.example.com',
          'good-edge.example.com',
        ]);
        // Healthy endpoint is promoted to index 0 for subsequent calls.
        expect(
          storage.cachedApiEndpoints.first,
          'https://good-edge.example.com',
        );
      },
    );

    test(
      'surfaces 401 session invalid inside E2EE envelope and HTTP 426 upgrade required without futile failover',
      () async {
        storage.setActiveServerUrl('https://origin.example.com');
        storage.setApiEndpoints(const [
          'https://edge1.example.com',
          'https://origin.example.com',
        ]);

        var calls = 0;
        final unauthClient = clientWith((options, bodyText) async {
          calls++;
          final envelope = jsonDecode(bodyText) as Map<String, Object?>;
          final opened = await server.openEnvelope(options.uri.path, envelope);
          return _jsonBody(
            await opened.seal({
              'ret': 0,
              'http_status': 401,
              'code': 'unauthorized',
              'msg': '登录会话已过期',
            }),
          );
        });

        await expectLater(
          unauthClient.downloadSubscription(
            serverUrl: 'https://origin.example.com',
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
        expect(calls, 1);

        var upgradeCalls = 0;
        final upgradeClient = clientWith((_, _) async {
          upgradeCalls++;
          return _jsonBody({
            'ret': 0,
            'code': 'client_upgrade_required',
            'msg': '请升级至最新版人间之里 (v1.1.0+)',
          }, status: 426);
        });

        await expectLater(
          upgradeClient.fetchBootstrap(
            serverUrl: 'https://origin.example.com',
            accessToken: 'tok',
          ),
          throwsA(
            isA<YoukoMixApiException>().having(
              (e) => e.isUpgradeRequired,
              'isUpgradeRequired',
              isTrue,
            ),
          ),
        );
        expect(upgradeCalls, 1);

        // Unauthenticated outer 401 from a reverse proxy must NOT set isSessionInvalid
        // and must fail over to the healthy origin endpoint.
        final forged401Client = clientWith((options, bodyText) async {
          if (options.uri.host == 'edge1.example.com') {
            return _jsonBody({
              'ret': 0,
              'code': 'unauthorized',
              'msg': 'forged proxy 401',
            }, status: 401);
          }
          final envelope = jsonDecode(bodyText) as Map<String, Object?>;
          final opened = await server.openEnvelope(options.uri.path, envelope);
          return _jsonBody(
            await opened.seal({
              'ret': 1,
              'http_status': 200,
              'data': {
                'user': {'id': 9, 'email': 'safe@example.com'},
              },
            }),
          );
        });
        final recovered = await forged401Client.fetchBootstrap(
          serverUrl: 'https://origin.example.com',
          accessToken: 'valid_tok',
        );
        expect(recovered.user.email, 'safe@example.com');
      },
    );
  });
}
