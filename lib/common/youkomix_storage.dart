import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/models/youkomix.dart';
import 'package:path/path.dart' show join;

import 'file.dart';
import 'path.dart';

const youkomixSessionFileName = 'youkomix_session.json';

class YoukoMixSessionStorage {
  final Future<String> Function() _homeDirProvider;
  String? _cachedServerUrl;

  YoukoMixSessionStorage({Future<String> Function()? homeDirProvider})
    : _homeDirProvider = homeDirProvider ?? (() => appPath.homeDirPath);

  String? get activeServerUrl {
    final cached = _cachedServerUrl;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final fallback = defaultYoukoMixServerUrl.trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    return fallback.isEmpty ? null : fallback;
  }

  void setActiveServerUrl(String? serverUrl) {
    final cleaned = serverUrl?.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedServerUrl = (cleaned == null || cleaned.isEmpty) ? null : cleaned;
  }

  Future<String> get sessionFilePath async {
    final homeDir = await _homeDirProvider();
    return join(homeDir, youkomixSessionFileName);
  }

  Future<YoukoMixSession?> loadSession() async {
    try {
      final file = File(await sessionFilePath);
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await file.safeDelete();
        return null;
      }
      final session = YoukoMixSession.fromJson(
        Map<String, Object?>.from(decoded),
      );
      if (session.serverUrl.isEmpty || session.accessToken.isEmpty) {
        await file.safeDelete();
        return null;
      }
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (session.expiresAt > 0 && session.expiresAt <= nowSeconds) {
        await file.safeDelete();
        return null;
      }
      setActiveServerUrl(session.serverUrl);
      return session;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> saveSession(YoukoMixSession session) async {
    final path = await sessionFilePath;
    final encoded = const JsonEncoder.withIndent(
      '  ',
    ).convert(session.toJson());
    await File(path).writeAsStringAtomically('$encoded\n');
    setActiveServerUrl(session.serverUrl);
    if (Platform.isLinux || Platform.isMacOS) {
      try {
        await Process.run('chmod', ['600', path]);
      } on ProcessException {
        return;
      }
    }
  }

  Future<void> clearSession() async {
    final path = await sessionFilePath;
    await File(path).safeDelete();
  }
}

final youkomixStorage = YoukoMixSessionStorage();
