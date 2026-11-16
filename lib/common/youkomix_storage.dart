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
  final Map<String, List<String>> _endpointsByOrigin = {};
  final Set<String> _mutatedOrigins = {};
  Future<void>? _endpointsLoadFuture;
  bool _endpointsLoaded = false;
  Future<void> _persistQueue = Future.value();

  YoukoMixSessionStorage({Future<String> Function()? homeDirProvider})
    : _homeDirProvider = homeDirProvider ?? (() => appPath.homeDirPath);

  static String _cleanUrl(String? raw) {
    return raw?.trim().replaceAll(RegExp(r'/+$'), '') ?? '';
  }

  String? get activeServerUrl {
    final cached = _cachedServerUrl;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    final fallback = _cleanUrl(defaultYoukoMixServerUrl);
    return fallback.isEmpty ? null : fallback;
  }

  List<String> get cachedApiEndpoints {
    final active = activeServerUrl;
    if (active == null || active.isEmpty) {
      return const [];
    }
    return _endpointsByOrigin[active] ?? const [];
  }

  List<String> endpointsForOrigin(String originUrl) {
    final clean = _cleanUrl(originUrl);
    if (clean.isEmpty) {
      return const [];
    }
    return _endpointsByOrigin[clean] ?? const [];
  }

  void setActiveServerUrl(String? serverUrl) {
    final cleaned = _cleanUrl(serverUrl);
    _cachedServerUrl = cleaned.isEmpty ? null : cleaned;
  }

  void setApiEndpoints(
    Iterable<String> endpoints, {
    String? origin,
    bool persist = true,
  }) {
    final normalized = parseYoukoMixEndpointList(endpoints.toList());
    final originKey = _cleanUrl(origin ?? activeServerUrl);
    if (normalized.isEmpty || originKey.isEmpty) {
      return;
    }
    _mutatedOrigins.add(originKey);
    _endpointsByOrigin[originKey] = normalized;
    if (persist) {
      _enqueuePersist();
    }
  }

  void promoteEndpoint(String endpoint, {String? origin, bool persist = true}) {
    final clean = _cleanUrl(endpoint);
    final originKey = _cleanUrl(origin ?? activeServerUrl);
    if (clean.isEmpty || originKey.isEmpty) {
      return;
    }
    final existing = _endpointsByOrigin[originKey];
    if (existing == null ||
        existing.isEmpty ||
        existing.first == clean ||
        !existing.contains(clean)) {
      return;
    }
    final reordered = List<String>.unmodifiable(<String>[
      clean,
      for (final item in existing)
        if (item != clean) item,
    ]);
    _mutatedOrigins.add(originKey);
    _endpointsByOrigin[originKey] = reordered;
    if (persist) {
      _enqueuePersist();
    }
  }

  List<String> candidateEndpoints(String primaryServerUrl) {
    final cleanPrimary = _cleanUrl(primaryServerUrl);
    if (cleanPrimary.isEmpty) {
      return const [];
    }
    final scoped = _endpointsByOrigin[cleanPrimary];
    if (scoped != null && scoped.isNotEmpty) {
      if (scoped.contains(cleanPrimary)) {
        return scoped;
      }
      return List.unmodifiable([...scoped, cleanPrimary]);
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

  Future<List<String>> ensureEndpointsLoaded([String? origin]) async {
    if (!_endpointsLoaded) {
      await (_endpointsLoadFuture ??= _loadEndpointsFromDisk());
    }
    final key = _cleanUrl(origin ?? activeServerUrl);
    if (key.isEmpty) {
      return const [];
    }
    return _endpointsByOrigin[key] ?? const [];
  }

  Future<void> flushPendingWrites() => _persistQueue;

  Future<void> _loadEndpointsFromDisk() async {
    try {
      final file = File(await endpointsFilePath);
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) {
          final originsRaw = decoded['origins'];
          if (originsRaw is Map) {
            for (final entry in originsRaw.entries) {
              final originKey = _cleanUrl(entry.key?.toString());
              if (originKey.isEmpty || _mutatedOrigins.contains(originKey)) {
                continue;
              }
              final parsed = parseYoukoMixEndpointList(entry.value);
              if (parsed.isNotEmpty) {
                _endpointsByOrigin[originKey] = parsed;
              }
            }
          } else {
            final legacyKey = activeServerUrl ?? '';
            if (legacyKey.isNotEmpty && !_mutatedOrigins.contains(legacyKey)) {
              final parsed = parseYoukoMixEndpointList(
                decoded['api_endpoints'],
              );
              if (parsed.isNotEmpty) {
                _endpointsByOrigin[legacyKey] = parsed;
              }
            }
          }
        }
      }
    } catch (_) {
    } finally {
      _endpointsLoaded = true;
    }
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
      final originKey = _cleanUrl(session.serverUrl);
      if (session.apiEndpoints.isNotEmpty &&
          originKey.isNotEmpty &&
          (_endpointsByOrigin[originKey]?.isEmpty ?? true)) {
        setApiEndpoints(
          session.apiEndpoints,
          origin: originKey,
          persist: false,
        );
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
    final originKey = _cleanUrl(session.serverUrl);
    if (session.apiEndpoints.isNotEmpty && originKey.isNotEmpty) {
      setApiEndpoints(session.apiEndpoints, origin: originKey);
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

  void _enqueuePersist() {
    _persistQueue = _persistQueue
        .then((_) => _writeSnapshotToDisk())
        .catchError((_) {});
  }

  Future<void> _writeSnapshotToDisk() async {
    try {
      final snapshot = <String, List<String>>{
        for (final entry in _endpointsByOrigin.entries)
          if (entry.key.isNotEmpty && entry.value.isNotEmpty)
            entry.key: entry.value,
      };
      final path = await endpointsFilePath;
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert({'origins': snapshot});
      await File(path).writeAsStringAtomically('$encoded\n');
    } catch (_) {}
  }
}

final youkomixStorage = YoukoMixSessionStorage();
