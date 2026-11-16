import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:fl_clash/models/youkomix.dart';
import 'package:flutter/foundation.dart';

import 'print.dart';
import 'protocol.dart';

sealed class YoukoMixDeepLink {
  const YoukoMixDeepLink();
}

@immutable
final class YoukoMixAuthDeepLink extends YoukoMixDeepLink {
  final String code;
  final String? serverUrl;

  const YoukoMixAuthDeepLink({required this.code, this.serverUrl});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixAuthDeepLink &&
          other.code == code &&
          other.serverUrl == serverUrl;

  @override
  int get hashCode => Object.hash(code, serverUrl);
}

@immutable
final class YoukoMixSyncDeepLink extends YoukoMixDeepLink {
  final YoukoMixSubPreference? mode;

  const YoukoMixSyncDeepLink({this.mode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoukoMixSyncDeepLink && other.mode == mode;

  @override
  int get hashCode => Object.hash(YoukoMixSyncDeepLink, mode);
}

YoukoMixDeepLink? parseYoukoMixDeepLink(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(text);
  if (uri == null) {
    return null;
  }
  return parseYoukoMixDeepLinkUri(uri);
}

YoukoMixDeepLink? parseYoukoMixDeepLinkUri(Uri uri) {
  if (!protocolSchemes.contains(uri.scheme.toLowerCase())) {
    return null;
  }
  if (uri.path.isNotEmpty && uri.path != '/') {
    return null;
  }
  switch (uri.host.toLowerCase()) {
    case 'auth':
      final code = uri.queryParameters['code']?.trim();
      if (code == null || code.isEmpty) {
        return null;
      }
      final rawServer = uri.queryParameters['server']?.trim();
      String? serverUrl;
      if (rawServer != null && rawServer.isNotEmpty) {
        final parsedServer = Uri.tryParse(rawServer);
        final validScheme =
            parsedServer != null &&
            (parsedServer.scheme == 'https' || parsedServer.scheme == 'http');
        if (!validScheme || parsedServer.host.isEmpty) {
          return null;
        }
        serverUrl = rawServer;
      }
      return YoukoMixAuthDeepLink(code: code, serverUrl: serverUrl);
    case 'sync':
      final rawMode = uri.queryParameters['mode']?.trim().toLowerCase();
      final mode = switch (rawMode) {
        'exclusive' => YoukoMixSubPreference.exclusive,
        'standard' => YoukoMixSubPreference.standard,
        _ => null,
      };
      return YoukoMixSyncDeepLink(mode: mode);
    default:
      return null;
  }
}

String? youkoMixLinkFromQrCodes(Iterable<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text == null || text.isEmpty) {
      continue;
    }
    if (parseYoukoMixDeepLink(text) != null) {
      return text;
    }
  }
  return null;
}

class LinkManager {
  static LinkManager? _instance;
  StreamSubscription? subscription;
  Uri? _pendingUri;

  LinkManager._internal();

  @visibleForTesting
  Stream<Uri> Function() uriLinkStream = () => AppLinks().uriLinkStream;

  void seedInitialLink(List<String> args) {
    for (final arg in args) {
      final uri = Uri.tryParse(arg.trim());
      if (uri != null && protocolSchemes.contains(uri.scheme.toLowerCase())) {
        _pendingUri = uri;
        return;
      }
    }
  }

  Future<void> initAppLinksListen(
    void Function(YoukoMixDeepLink link) onDeepLink,
  ) async {
    destroy();
    subscription = uriLinkStream().listen((uri) {
      _handle(uri, onDeepLink);
    });
    final pending = _pendingUri;
    _pendingUri = null;
    if (pending != null) {
      _handle(pending, onDeepLink);
    }
  }

  void _handle(Uri uri, void Function(YoukoMixDeepLink link) onDeepLink) {
    commonPrint.log('onAppLink: $uri');
    final link = parseYoukoMixDeepLinkUri(uri);
    if (link != null) {
      onDeepLink(link);
    }
  }

  void destroy() {
    if (subscription != null) {
      subscription?.cancel();
      subscription = null;
    }
  }

  factory LinkManager() {
    _instance ??= LinkManager._internal();
    return _instance!;
  }
}

final linkManager = LinkManager();
