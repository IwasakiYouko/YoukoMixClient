import 'dart:async';

import 'package:fl_clash/common/link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<Uri> links;
  late List<YoukoMixDeepLink> received;

  setUp(() {
    links = StreamController<Uri>.broadcast();
    received = [];
    linkManager.uriLinkStream = () => links.stream;
  });

  tearDown(() async {
    linkManager.destroy();
    await links.close();
  });

  Future<void> listen() async {
    await linkManager.initAppLinksListen(received.add);
  }

  Future<void> emit(String uri) async {
    links.add(Uri.parse(uri));
    await Future<void>.delayed(Duration.zero);
  }

  test('LinkManager is a singleton', () {
    expect(LinkManager(), same(linkManager));
  });

  test('an auth link reports its code and server url', () async {
    await listen();

    await emit(
      'youkomix://auth?code=otc_123&server=https%3A%2F%2Fpanel.example.com',
    );

    expect(received, [
      const YoukoMixAuthDeepLink(
        code: 'otc_123',
        serverUrl: 'https://panel.example.com',
      ),
    ]);
  });

  test('a sync link reports YoukoMixSyncDeepLink', () async {
    await listen();

    await emit('youkomix://sync');

    expect(received, [const YoukoMixSyncDeepLink()]);
  });

  test('an auth link without a code or with blank code is ignored', () async {
    await listen();

    await emit('youkomix://auth');
    await emit('youkomix://auth?code=');
    await emit('youkomix://auth?code=%20');
    await emit('youkomix://auth?code=otc_123&server=javascript:alert(1)');

    expect(received, isEmpty);
  });

  test('install-config and legacy schemes are strictly ignored', () async {
    await listen();

    await emit('youkomix://install-config?url=https://example.com/a.yaml');
    await emit('flclash://install-config?url=https://example.com/a.yaml');
    await emit('clash://install-config?url=https://example.com/a.yaml');
    await emit('clashmeta://install-config?url=https://example.com/a.yaml');
    await emit('youkomix://auth/extra?code=otc_123');

    expect(received, isEmpty);
  });

  test('listening again replaces the previous subscription', () async {
    await listen();
    final first = linkManager.subscription;

    await listen();

    expect(linkManager.subscription, isNot(same(first)));

    await emit('youkomix://auth?code=otc_456');

    expect(received, [const YoukoMixAuthDeepLink(code: 'otc_456')]);
  });

  test(
    'a seeded launch argument is delivered once a listener attaches',
    () async {
      linkManager.seedInitialLink([
        '--verbose',
        'youkomix://auth?code=otc_789',
      ]);

      expect(received, isEmpty);

      await listen();

      expect(received, [const YoukoMixAuthDeepLink(code: 'otc_789')]);

      await listen();

      expect(received, [const YoukoMixAuthDeepLink(code: 'otc_789')]);
    },
  );

  test('launch arguments without a known scheme are ignored', () async {
    linkManager.seedInitialLink([
      'https://example.com/a.yaml',
      'clash://install-config?url=https://example.com/a.yaml',
      'not a uri',
    ]);

    await listen();

    expect(received, isEmpty);
  });

  test('destroy stops delivery and is safe to repeat', () async {
    await listen();

    linkManager.destroy();
    linkManager.destroy();
    await emit('youkomix://auth?code=otc_999');

    expect(linkManager.subscription, isNull);
    expect(received, isEmpty);
  });

  group('youkoMixLinkFromQrCodes', () {
    test('accepts youkomix auth and sync links with whitespace', () {
      expect(
        youkoMixLinkFromQrCodes([' youkomix://auth?code=otc_1\n']),
        'youkomix://auth?code=otc_1',
      );
      expect(youkoMixLinkFromQrCodes([' youkomix://sync ']), 'youkomix://sync');
    });

    test(
      'strictly rejects third-party urls, install-config, and share links',
      () {
        expect(
          youkoMixLinkFromQrCodes([
            null,
            '',
            'plain text',
            'https://example.com/sub?token=1',
            'http://example.com/sub.yaml',
            'youkomix://install-config?url=https://example.com/a.yaml',
            'flclash://install-config?url=https://example.com/a.yaml',
            'clash://install-config?url=https://example.com/a.yaml',
            'clashmeta://install-config?url=https://example.com/a.yaml',
            'vmess://eyJhZGQiOiIxLjIuMy40In0=',
            'vless://uuid@1.2.3.4:443#node',
            'ss://YWVzLTI1Ni1nY206cGFzcw@1.2.3.4:8388',
          ]),
          isNull,
        );
      },
    );

    test('returns the first valid youkomix link', () {
      expect(
        youkoMixLinkFromQrCodes([
          'https://thirdparty.example/sub.yaml',
          'youkomix://auth?code=first',
          'youkomix://sync',
        ]),
        'youkomix://auth?code=first',
      );
    });
  });
}
