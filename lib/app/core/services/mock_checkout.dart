import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dev/staging only: opens the backend's mock checkout and completes once
/// the donor is back in the app, so the caller can re-fetch the request.
///
/// `launchUrl` returns as soon as the browser opens, so the return is read
/// from the app resuming. iOS uses Safari, as real donations will, because
/// an in-app Safari sheet doesn't pause the app.
Future<void> launchMockCheckout(String url) async {
  final back = Completer<void>();
  final listener = AppLifecycleListener(
    onResume: () {
      if (!back.isCompleted) back.complete();
    },
  );
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: Platform.isIOS
          ? LaunchMode.externalApplication
          : LaunchMode.inAppBrowserView,
    );
    if (opened) {
      await back.future.timeout(const Duration(minutes: 30), onTimeout: () {});
    }
  } finally {
    listener.dispose();
  }
}
