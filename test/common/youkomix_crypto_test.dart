import 'package:fl_clash/common/youkomix_api.dart';
import 'package:fl_clash/common/youkomix_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/youkomix_e2ee_server.dart';

void main() {
  group('YoukoMixCrypto', () {
    test('parses server public key tokens and rejects malformed keys', () {
      expect(YoukoMixServerPublicKey.tryParse(''), isNull);
      expect(YoukoMixServerPublicKey.tryParse('only-one-part'), isNull);
      expect(YoukoMixServerPublicKey.tryParse('short.short'), isNull);
      expect(
        () => YoukoMixServerPublicKey.parse('bad'),
        throwsA(isA<YoukoMixApiException>()),
      );
    });

    test(
      'verifies Ed25519 signed public responses and blocks key mismatch or tampering',
      () async {
        final serverA = await FakeYoukoMixE2eeServer.create(0x11);
        final serverB = await FakeYoukoMixE2eeServer.create(0x22);
        final keyA = YoukoMixServerPublicKey.parse(serverA.pubkeyToken);
        final keyB = YoukoMixServerPublicKey.parse(serverB.pubkeyToken);

        final signed = await serverA.signPublicData('/api/v1/client/meta', {
          'app_name': '人间之里',
          'api_endpoints': ['https://edge1.example.com'],
        });

        final verified = await YoukoMixCrypto.verifyPublicResponse(
          routeKey: '/api/v1/client/meta',
          json: signed,
          pinnedKey: keyA,
        );
        expect(verified.data['app_name'], '人间之里');
        expect(verified.serverKey, keyA);

        // Missing pinned key must fail closed without trusting advertisedKey.
        await expectLater(
          YoukoMixCrypto.verifyPublicResponse(
            routeKey: '/api/v1/client/meta',
            json: signed,
            pinnedKey: null,
          ),
          throwsA(
            isA<YoukoMixApiException>().having(
              (e) => e.errorCode,
              'errorCode',
              'missing_server_pubkey',
            ),
          ),
        );

        // Wrong pinned key must fail closed.
        await expectLater(
          YoukoMixCrypto.verifyPublicResponse(
            routeKey: '/api/v1/client/meta',
            json: signed,
            pinnedKey: keyB,
          ),
          throwsA(
            isA<YoukoMixApiException>().having(
              (e) => e.errorCode,
              'errorCode',
              'signature_invalid',
            ),
          ),
        );

        // Wrong route AAD must fail closed.
        await expectLater(
          YoukoMixCrypto.verifyPublicResponse(
            routeKey: '/api/v1/client/release',
            json: signed,
            pinnedKey: keyA,
          ),
          throwsA(
            isA<YoukoMixApiException>().having(
              (e) => e.errorCode,
              'errorCode',
              'signature_invalid',
            ),
          ),
        );

        // Tampered payload_b64 must fail closed.
        final tampered = <String, Object?>{
          ...signed,
          'payload_b64': YoukoMixCrypto.b64uEncode([123, 125]),
        };
        await expectLater(
          YoukoMixCrypto.verifyPublicResponse(
            routeKey: '/api/v1/client/meta',
            json: tampered,
            pinnedKey: keyA,
          ),
          throwsA(isA<YoukoMixApiException>()),
        );
      },
    );

    test(
      'performs full X25519 + HKDF-SHA256 + ChaCha20-Poly1305 + Ed25519 round-trip',
      () async {
        final server = await FakeYoukoMixE2eeServer.create(0x55);
        final serverKey = YoukoMixServerPublicKey.parse(server.pubkeyToken);

        final sealedReq = await YoukoMixCrypto.sealRequest(
          routeKey: '/api/v1/client/subscription',
          serverKey: serverKey,
          accessToken: 'ykc_live_token',
          payload: {'mode': 'exclusive'},
        );

        final openedOnServer = await server.openEnvelope(
          '/api/v1/client/subscription',
          sealedReq.envelope,
        );
        expect(openedOnServer.token, 'ykc_live_token');
        expect(openedOnServer.payload['mode'], 'exclusive');

        final respEnvelope = await openedOnServer.seal({
          'ret': 1,
          'http_status': 200,
          'data': {'mode': 'exclusive', 'title': '人间之里'},
        });

        final decrypted = await YoukoMixCrypto.openResponse(
          request: sealedReq,
          envelope: respEnvelope,
        );
        expect(decrypted['ret'], 1);
        expect((decrypted['data'] as Map)['title'], '人间之里');

        // Tampering with response signature fails closed.
        final badSig = <String, Object?>{
          ...respEnvelope,
          'sig': YoukoMixCrypto.b64uEncode(List<int>.filled(64, 0)),
        };
        await expectLater(
          YoukoMixCrypto.openResponse(request: sealedReq, envelope: badSig),
          throwsA(
            isA<YoukoMixApiException>().having(
              (e) => e.errorCode,
              'errorCode',
              'signature_invalid',
            ),
          ),
        );
      },
    );
  });
}
