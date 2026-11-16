import 'dart:io';

import 'package:fl_clash/common/youkomix_storage.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late YoukoMixSessionStorage storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('youkomix-storage-test-');
    storage = YoukoMixSessionStorage(homeDirProvider: () async => tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('saves, loads, updates activeServerUrl, and clears session', () async {
    expect(await storage.loadSession(), isNull);

    final futureExpiry =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 86400;
    final session = YoukoMixSession(
      serverUrl: 'https://panel.example.com/',
      accessToken: 'ymx_live_token',
      expiresAt: futureExpiry,
      apiEndpoints: const [
        'https://edge1.example.com',
        'https://panel.example.com',
      ],
      bootstrap: const YoukoMixBootstrap(
        user: YoukoMixUser(id: 5, email: 'alice@example.com'),
      ),
    );

    await storage.saveSession(session);
    expect(storage.activeServerUrl, 'https://panel.example.com');
    expect(storage.candidateEndpoints('https://panel.example.com'), [
      'https://edge1.example.com',
      'https://panel.example.com',
    ]);

    storage.promoteEndpoint('https://panel.example.com', persist: false);
    expect(storage.candidateEndpoints('https://panel.example.com'), [
      'https://panel.example.com',
      'https://edge1.example.com',
    ]);

    final freshReader = YoukoMixSessionStorage(
      homeDirProvider: () async => tempDir.path,
    );
    final loaded = await freshReader.loadSession();
    expect(loaded, session);
    expect(freshReader.activeServerUrl, 'https://panel.example.com');

    await storage.clearSession();
    expect(await storage.loadSession(), isNull);
  });

  test('evicts expired or malformed session files automatically', () async {
    final path = await storage.sessionFilePath;

    const expired = YoukoMixSession(
      serverUrl: 'https://panel.example.com',
      accessToken: 'ymx_old',
      expiresAt: 1000,
    );
    await storage.saveSession(expired);
    expect(await storage.loadSession(), isNull);
    expect(File(path).existsSync(), isFalse);

    File(path).writeAsStringSync('["not-a-map"]');
    expect(await storage.loadSession(), isNull);
    expect(File(path).existsSync(), isFalse);

    File(path).writeAsStringSync('{invalid json');
    expect(await storage.loadSession(), isNull);
  });
}
