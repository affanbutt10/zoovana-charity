import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../data/repositories/session_repository.dart';
import '../../routes/app_routes.dart';
import '../../routes/shell_router.dart';
import '../config/app_config.dart';

/// Opens `zoovana-charity://donor/request/{id}` and
/// `zoovana-charity://operator/task/{id}` from notifications and the OS.
/// The target screen always re-fetches; nothing renders from the payload.
class DeepLinkService {
  DeepLinkService(this._session);

  final SessionRepository _session;
  StreamSubscription<Uri>? _subscription;

  /// A link that arrived before a shell was ready; opened after routing.
  Uri? _pending;

  void listen() {
    try {
      _subscription = AppLinks().uriLinkStream.listen(
        _handle,
        onError: (Object _) {},
      );
    } on MissingPluginException {
      // Not available in tests.
    }
  }

  void _handle(Uri uri) {
    // The mock checkout's return link only brings the app back; the
    // checkout re-fetches the request on resume.
    if (uri.host == 'feeding') return;
    if (!open(uri.toString())) _pending = uri;
  }

  /// Opens any link that arrived during startup.
  void openPending() {
    final uri = _pending;
    _pending = null;
    if (uri != null) open(uri.toString());
  }

  /// Returns false when [link] isn't for the current shell or session.
  bool open(String? link) {
    final uri = link == null ? null : Uri.tryParse(link);
    final session = _session.current;
    if (uri == null || uri.scheme != AppConfig.deepLinkScheme) return false;
    if (session == null || !_session.hasActiveSession) return false;
    final shell = uri.host;
    final segments = uri.pathSegments;
    if (!ShellRouter.linkMatches(session, shell) || segments.length < 2) {
      return false;
    }
    final id = segments[1];
    switch ((shell, segments.first)) {
      case ('donor', 'request'):
        Get.toNamed<void>(AppRoutes.requestDetails, arguments: id);
      case ('operator', 'task'):
        Get.toNamed<void>(AppRoutes.providerJobDetails, arguments: id);
      default:
        return false;
    }
    return true;
  }

  void dispose() => _subscription?.cancel();
}
