import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/models/youkomix.dart';
import 'package:path/path.dart' show join;

import 'file.dart';
import 'path.dart';

const youkomixSessionFileName = 'youkomix_session.json';
const youkomixEndpointsFileName = 'youkomix_endpoints.json';

class YoukoMixSessionStorage {
  final Future<String> Function() _homeDirProvider;
  String? _cachedServerUrl;
  List<String> _cachedApiEndpoints = const [];
  bool _endpointsLoaded = false;

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

  List<String> get cachedApiEndpoints => _cachedApiEndpoints;

  void setActiveServerUrl(String? serverUrl) {
    final cleaned = serverUrl?.trim().replaceAll(RegExp(r'/+$'), '');
    _cachedServerUrl = (cleaned == null || cleaned.isEmpty) ? null : cleaned;
  }

  void setApiEndpoints(Iterable<String> endpoints, {bool persist = true}) {
    final normalized = parseYoukoMixEndpointList(endpoints.toList());
    if (normalized.isEmpty) {
      return;
    }
    _cachedApiEndpoints = normalized;
    _endpointsLoaded = true;
    if (persist) {
      unawaited(_persistEndpointsQuietly(normalized));
    }
  }

  void promoteEndpoint(String endpoint, {bool persist = true}) {
    final clean = endpoint.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean.isEmpty || _cachedApiEndpoints.isEmpty) {
      return;
    }
    if (_cachedApiEndpoints.first == clean ||
        !_cachedApiEndpoints.contains(clean)) {
      return;
    }
    final reordered = <String>[
      clean,
      for (final item in _cachedApiEndpoints)
        if (item != clean) item,
    ];
    _cachedApiEndpoints = List.unmodifiable(reordered);
    if (persist) {
      unawaited(_persistEndpointsQuietly(_cachedApiEndpoints));
    }
  }

  List<String> candidateEndpoints(String primaryServerUrl) {
    final cleanPrimary = primaryServerUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (cleanPrimary.isEmpty) {
      return _cachedApiEndpoints;
    }
    if (_cachedApiEndpoints.isNotEmpty &&
        (_cachedApiEndpoints.contains(cleanPrimary) ||
            cleanPrimary == activeServerUrl)) {
      if (_cachedApiEndpoints.contains(cleanPrimary)) {
        return _cachedApiEndpoints;
      }
      return List.unmodifiable([..._cachedApiEndpoints, cleanPrimary]);
    }
    return List.unmodifiable([cleanPrimary]);
  }

  Future<String> get sessionFilePath async {
    final homeDir = await _homeDirProvider();
    return join(homeDir, youkomixSessionFileName);
  }

  Future<String> get endpointsFilePath async {
    final homeDir = await _homeDirProvider();
    return join(homeDir, youkomixEndpointsFileName);
  }

  Future<List<String>> ensureEndpointsLoaded() async {
    if (_endpointsLoaded) {
      return _cachedApiEndpoints;
    }
    _endpointsLoaded = true;
    try {
      final file = File(await endpointsFilePath);
      if (!await file.exists()) {
        return _cachedApiEndpoints;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map) {
        final parsed = parseYoukoMixEndpointList(decoded['api_endpoints']);
        if (parsed.isNotEmpty) {
          _cachedApiEndpoints = parsed;
        }
      }
    } catch (_) {}
    return _cachedApiEndpoints;
  }

  Future<YoukoMixSession?> loadSession() async {
    await ensureEndpointsLoaded();
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
      if (session.apiEndpoints.isNotEmpty) {
        setApiEndpoints(session.apiEndpoints, persist: false);
      }
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
    if (session.apiEndpoints.isNotEmpty) {
      setApiEndpoints(session.apiEndpoints);
    }
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

  Future<void> _persistEndpointsQuietly(List<String> endpoints) async {
    try {
      final path = await endpointsFilePath;
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert({'api_endpoints': endpoints});
      await File(path).writeAsStringAtomically('$encoded\n');
    } catch (_) {}
  }
}

final youkomixStorage = YoukoMixSessionStorage();
