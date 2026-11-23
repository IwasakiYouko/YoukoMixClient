import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:flutter/foundation.dart';

import 'youkomix_api.dart';

const defaultYoukoMixServerPubkey = String.fromEnvironment(
  'YOUKOMIX_SERVER_PUBKEY',
  defaultValue: '',
);

final _b64uPattern = RegExp(r'^[A-Za-z0-9_-]+$');

@immutable
class YoukoMixServerPublicKey {
  final Uint8List ed25519Bytes;
  final Uint8List x25519Bytes;
  final String token;

  const YoukoMixServerPublicKey._({
    required this.ed25519Bytes,
    required this.x25519Bytes,
    required this.token,
  });

  static YoukoMixServerPublicKey? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parts = trimmed.split('.');
    if (parts.length != 2) {
      return null;
    }
    final ed = YoukoMixCrypto.b64uDecode(parts[0]);
    final x = YoukoMixCrypto.b64uDecode(parts[1]);
    if (ed.length != 32 || x.length != 32) {
      return null;
    }
    final canonicalToken =
        '${YoukoMixCrypto.b64uEncode(ed)}.${YoukoMixCrypto.b64uEncode(x)}';
    return YoukoMixServerPublicKey._(
      ed25519Bytes: ed,
      x25519Bytes: x,
      token: canonicalToken,
    );
  }

  static YoukoMixServerPublicKey parse(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) {
      final l10n = AppLocalizations.maybeCurrent;
      throw YoukoMixApiException(
        message: l10n?.youkomixErrInvalidServerPubkey ?? '服务端安全公钥格式无效',
        errorCode: 'invalid_server_pubkey',
      );
    }
    return parsed;
  }

  SimplePublicKey get ed25519PublicKey =>
      SimplePublicKey(ed25519Bytes, type: KeyPairType.ed25519);

  SimplePublicKey get x25519PublicKey =>
      SimplePublicKey(x25519Bytes, type: KeyPairType.x25519);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixServerPublicKey && other.token == token;

  @override
  int get hashCode => token.hashCode;
}

@immutable
class YoukoMixVerifiedPublicPayload {
  final Map<String, Object?> data;
  final YoukoMixServerPublicKey serverKey;

  const YoukoMixVerifiedPublicPayload({
    required this.data,
    required this.serverKey,
  });
}

@immutable
class YoukoMixSealedRequest {
  final String routeKey;
  final Map<String, Object?> envelope;
  final Uint8List clientPublicKeyBytes;
  final Uint8List requestNonceBytes;
  final SecretKey sharedSecret;
  final YoukoMixServerPublicKey serverKey;

  const YoukoMixSealedRequest({
    required this.routeKey,
    required this.envelope,
    required this.clientPublicKeyBytes,
    required this.requestNonceBytes,
    required this.sharedSecret,
    required this.serverKey,
  });
}

abstract final class YoukoMixCrypto {
  static const int protocolVersion = 1;
  static const int _nonceBytes = 12;
  static const int _keyBytes = 32;
  static const int _macBytes = 16;
  static const int _sigBytes = 64;

  static final X25519 _x25519 = X25519();
  static final Ed25519 _ed25519 = Ed25519();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: _keyBytes);
  static final Cipher _aead = Chacha20.poly1305Aead();

  static String b64uEncode(List<int> raw) {
    return base64Url.encode(raw).replaceAll('=', '');
  }

  static Uint8List b64uDecode(String encoded) {
    if (encoded.isEmpty || !_b64uPattern.hasMatch(encoded)) {
      return Uint8List(0);
    }
    final pad = (4 - encoded.length % 4) % 4;
    try {
      return Uint8List.fromList(
        base64Url.decode(pad > 0 ? '$encoded${'=' * pad}' : encoded),
      );
    } on FormatException {
      return Uint8List(0);
    }
  }

  static Future<YoukoMixVerifiedPublicPayload> verifyPublicResponse({
    required String routeKey,
    required Map<String, Object?> json,
    required YoukoMixServerPublicKey? pinnedKey,
  }) async {
    final l10n = AppLocalizations.maybeCurrent;
    if (pinnedKey == null) {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrMissingServerPubkey ?? '客户端未配置预置安全公钥，已拒绝建立信任',
        errorCode: 'missing_server_pubkey',
      );
    }
    final rawPubkey = json['server_pubkey']?.toString().trim() ?? '';
    final advertisedKey = YoukoMixServerPublicKey.tryParse(rawPubkey);
    if (advertisedKey != null && advertisedKey != pinnedKey) {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrServerPubkeyMismatch ?? '服务端安全公钥不匹配，连接已被拦截',
        errorCode: 'signature_invalid',
      );
    }

    final payloadB64 = json['payload_b64']?.toString().trim() ?? '';
    final sigRaw = json['sig']?.toString().trim() ?? '';
    final sigBytes = b64uDecode(sigRaw);
    if (payloadB64.isEmpty || sigBytes.length != _sigBytes) {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrMissingSignature ?? '面板公开数据缺少有效的数字签名',
        errorCode: 'signature_invalid',
      );
    }

    final message = utf8.encode('v1|pub|$routeKey|$payloadB64');
    final verified = await _ed25519.verify(
      message,
      signature: Signature(sigBytes, publicKey: pinnedKey.ed25519PublicKey),
    );
    if (!verified) {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrSignatureInvalid ?? '面板数字签名校验未通过，响应可能被篡改',
        errorCode: 'signature_invalid',
      );
    }

    final payloadBytes = b64uDecode(payloadB64);
    if (payloadBytes.isEmpty) {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrInvalidSignedBody ?? '签名载荷格式无效',
        errorCode: 'invalid_envelope',
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(payloadBytes));
      if (decoded is! Map) {
        throw const FormatException('Expected JSON object');
      }
      return YoukoMixVerifiedPublicPayload(
        data: Map<String, Object?>.from(decoded),
        serverKey: pinnedKey,
      );
    } on FormatException {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrParseSignedFailed ?? '签名载荷解析失败',
        errorCode: 'invalid_envelope',
      );
    }
  }

  static Future<YoukoMixSealedRequest> sealRequest({
    required String routeKey,
    required YoukoMixServerPublicKey serverKey,
    Map<String, Object?>? payload,
    String? accessToken,
    int? timestampSeconds,
  }) async {
    final clientKeyPair = await _x25519.newKeyPair();
    final clientPub = await clientKeyPair.extractPublicKey();
    final cpkBytes = Uint8List.fromList(clientPub.bytes);
    final cpkB64 = b64uEncode(cpkBytes);

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: clientKeyPair,
      remotePublicKey: serverKey.x25519PublicKey,
    );

    final salt = Uint8List(_keyBytes * 2)
      ..setRange(0, _keyBytes, cpkBytes)
      ..setRange(_keyBytes, _keyBytes * 2, serverKey.x25519Bytes);
    final reqKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: salt,
      info: utf8.encode('youkomix-e2e-v1:req:$routeKey'),
    );

    final reqNonce = _randomBytes(_nonceBytes);
    final reqNonceB64 = b64uEncode(reqNonce);
    final reqAad = utf8.encode('v1|req|$routeKey|$cpkB64');
    final ts =
        timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    final innerJson = jsonEncode({
      'ts': ts,
      'token': accessToken?.trim() ?? '',
      'payload': payload ?? const <String, Object?>{},
    });

    final secretBox = await _aead.encrypt(
      utf8.encode(innerJson),
      secretKey: reqKey,
      nonce: reqNonce,
      aad: reqAad,
    );
    final ctBytes =
        Uint8List(secretBox.cipherText.length + secretBox.mac.bytes.length)
          ..setRange(0, secretBox.cipherText.length, secretBox.cipherText)
          ..setRange(
            secretBox.cipherText.length,
            secretBox.cipherText.length + secretBox.mac.bytes.length,
            secretBox.mac.bytes,
          );

    return YoukoMixSealedRequest(
      routeKey: routeKey,
      envelope: {
        'v': protocolVersion,
        'cpk': cpkB64,
        'n': reqNonceB64,
        'ct': b64uEncode(ctBytes),
      },
      clientPublicKeyBytes: cpkBytes,
      requestNonceBytes: reqNonce,
      sharedSecret: sharedSecret,
      serverKey: serverKey,
    );
  }

  static Future<Map<String, Object?>> openResponse({
    required YoukoMixSealedRequest request,
    required Map<String, Object?> envelope,
  }) async {
    final version = envelope['v'];
    final nonceB64 = envelope['n']?.toString().trim() ?? '';
    final ctB64 = envelope['ct']?.toString().trim() ?? '';
    final sigB64 = envelope['sig']?.toString().trim() ?? '';

    final respNonce = b64uDecode(nonceB64);
    final respBox = b64uDecode(ctB64);
    final sigBytes = b64uDecode(sigB64);
    final l10n = AppLocalizations.maybeCurrent;
    if (version != protocolVersion ||
        respNonce.length != _nonceBytes ||
        respBox.length < _macBytes ||
        sigBytes.length != _sigBytes) {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrInvalidEnvelope ?? '加密响应信封格式无效',
        errorCode: 'invalid_envelope',
      );
    }

    final cpkB64 = b64uEncode(request.clientPublicKeyBytes);
    final reqNonceB64 = b64uEncode(request.requestNonceBytes);
    final respAadText = 'v1|resp|${request.routeKey}|$cpkB64|$reqNonceB64';
    final signedMessage = utf8.encode('$respAadText|$nonceB64|$ctB64');
    final sigValid = await _ed25519.verify(
      signedMessage,
      signature: Signature(
        sigBytes,
        publicKey: request.serverKey.ed25519PublicKey,
      ),
    );
    if (!sigValid) {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrEnvelopeSigInvalid ?? '加密响应数字签名校验失败，连接已被拦截',
        errorCode: 'signature_invalid',
      );
    }

    final salt = Uint8List(_keyBytes * 2)
      ..setRange(0, _keyBytes, request.clientPublicKeyBytes)
      ..setRange(_keyBytes, _keyBytes * 2, request.serverKey.x25519Bytes);
    final respKey = await _hkdf.deriveKey(
      secretKey: request.sharedSecret,
      nonce: salt,
      info: utf8.encode('youkomix-e2e-v1:resp:${request.routeKey}'),
    );

    final cipherLen = respBox.length - _macBytes;
    final cipherText = Uint8List.sublistView(respBox, 0, cipherLen);
    final macBytes = Uint8List.sublistView(respBox, cipherLen);
    try {
      final clearBytes = await _aead.decrypt(
        SecretBox(cipherText, nonce: respNonce, mac: Mac(macBytes)),
        secretKey: respKey,
        aad: utf8.encode(respAadText),
      );
      final decoded = jsonDecode(utf8.decode(clearBytes));
      if (decoded is! Map) {
        throw const FormatException('Expected JSON object');
      }
      return Map<String, Object?>.from(decoded);
    } on SecretBoxAuthenticationError {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrDecryptFailed ?? '安全信道解密校验失败',
        errorCode: 'decrypt_failed',
      );
    } on FormatException {
      throw YoukoMixApiException(
        message: l10n?.youkomixErrInvalidEnvelopeBody ?? '加密响应内容格式无效',
        errorCode: 'invalid_envelope',
      );
    }
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = rng.nextInt(256);
    }
    return out;
  }
}
