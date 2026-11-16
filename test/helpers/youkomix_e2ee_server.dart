import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:fl_clash/common/youkomix_crypto.dart';

/// Deterministic pure-Dart mirror of SSPanel-UIM `ClientCryptoService` for tests.
class FakeYoukoMixE2eeServer {
  final SimpleKeyPair ed25519KeyPair;
  final SimplePublicKey ed25519PublicKey;
  final SimpleKeyPair x25519KeyPair;
  final SimplePublicKey x25519PublicKey;
  final String pubkeyToken;

  FakeYoukoMixE2eeServer._({
    required this.ed25519KeyPair,
    required this.ed25519PublicKey,
    required this.x25519KeyPair,
    required this.x25519PublicKey,
    required this.pubkeyToken,
  });

  static final Ed25519 _ed25519 = Ed25519();
  static final X25519 _x25519 = X25519();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final Cipher _aead = Chacha20.poly1305Aead();

  static Future<FakeYoukoMixE2eeServer> create([int seedByte = 0x42]) async {
    final edSeed = List<int>.filled(32, seedByte);
    final xSeed = List<int>.filled(32, (seedByte + 1) & 0xFF);
    final edKp = await _ed25519.newKeyPairFromSeed(edSeed);
    final edPk = await edKp.extractPublicKey();
    final xKp = await _x25519.newKeyPairFromSeed(xSeed);
    final xPk = await xKp.extractPublicKey();
    final token =
        '${YoukoMixCrypto.b64uEncode(edPk.bytes)}.${YoukoMixCrypto.b64uEncode(xPk.bytes)}';
    return FakeYoukoMixE2eeServer._(
      ed25519KeyPair: edKp,
      ed25519PublicKey: edPk,
      x25519KeyPair: xKp,
      x25519PublicKey: xPk,
      pubkeyToken: token,
    );
  }

  Future<Map<String, Object?>> signPublicData(
    String routeKey,
    Map<String, Object?> data,
  ) async {
    final enriched = <String, Object?>{
      ...data,
      'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    final canonical = jsonEncode(enriched);
    final payloadB64 = YoukoMixCrypto.b64uEncode(utf8.encode(canonical));
    final sig = await _ed25519.sign(
      utf8.encode('v1|pub|$routeKey|$payloadB64'),
      keyPair: ed25519KeyPair,
    );
    return {
      'ret': 1,
      'data': enriched,
      'payload_b64': payloadB64,
      'server_pubkey': pubkeyToken,
      'sig': YoukoMixCrypto.b64uEncode(sig.bytes),
    };
  }

  Future<
    ({
      String token,
      Map<String, Object?> payload,
      Future<Map<String, Object?>> Function(Map<String, Object?> inner) seal,
    })
  >
  openEnvelope(String routeKey, Map<String, Object?> envelope) async {
    final cpk = YoukoMixCrypto.b64uDecode(envelope['cpk']?.toString() ?? '');
    final reqNonce = YoukoMixCrypto.b64uDecode(envelope['n']?.toString() ?? '');
    final ct = YoukoMixCrypto.b64uDecode(envelope['ct']?.toString() ?? '');
    final shared = await _x25519.sharedSecretKey(
      keyPair: x25519KeyPair,
      remotePublicKey: SimplePublicKey(cpk, type: KeyPairType.x25519),
    );
    final salt = Uint8List.fromList([...cpk, ...x25519PublicKey.bytes]);
    final reqKey = await _hkdf.deriveKey(
      secretKey: shared,
      nonce: salt,
      info: utf8.encode('youkomix-e2e-v1:req:$routeKey'),
    );
    final reqAad = utf8.encode(
      'v1|req|$routeKey|${YoukoMixCrypto.b64uEncode(cpk)}',
    );
    final cipherLen = ct.length - 16;
    final plainBytes = await _aead.decrypt(
      SecretBox(
        ct.sublist(0, cipherLen),
        nonce: reqNonce,
        mac: Mac(ct.sublist(cipherLen)),
      ),
      secretKey: reqKey,
      aad: reqAad,
    );
    final inner = jsonDecode(utf8.decode(plainBytes)) as Map<String, Object?>;
    final rawPayload = inner['payload'];

    Future<Map<String, Object?>> seal(
      Map<String, Object?> innerResponse,
    ) async {
      final respNonce = List<int>.filled(12, 7);
      final respKey = await _hkdf.deriveKey(
        secretKey: shared,
        nonce: salt,
        info: utf8.encode('youkomix-e2e-v1:resp:$routeKey'),
      );
      final respAadText =
          'v1|resp|$routeKey|${YoukoMixCrypto.b64uEncode(cpk)}|${YoukoMixCrypto.b64uEncode(reqNonce)}';
      final box = await _aead.encrypt(
        utf8.encode(jsonEncode(innerResponse)),
        secretKey: respKey,
        nonce: respNonce,
        aad: utf8.encode(respAadText),
      );
      final boxBytes = [...box.cipherText, ...box.mac.bytes];
      final nonceB64 = YoukoMixCrypto.b64uEncode(respNonce);
      final boxB64 = YoukoMixCrypto.b64uEncode(boxBytes);
      final sig = await _ed25519.sign(
        utf8.encode('$respAadText|$nonceB64|$boxB64'),
        keyPair: ed25519KeyPair,
      );
      return {
        'v': 1,
        'n': nonceB64,
        'ct': boxB64,
        'sig': YoukoMixCrypto.b64uEncode(sig.bytes),
      };
    }

    return (
      token: inner['token']?.toString() ?? '',
      payload: rawPayload is Map
          ? Map<String, Object?>.from(rawPayload)
          : const <String, Object?>{},
      seal: seal,
    );
  }
}

/// Minimal valid 1x1 transparent PNG for widget & model tests.
const String tinyValidPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
