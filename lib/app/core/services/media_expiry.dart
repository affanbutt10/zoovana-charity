import 'dart:async';

import 'package:get/get.dart';

/// Re-fetches a screen shortly before its signed media URLs expire, so
/// photos keep loading while the screen stays open.
mixin MediaExpiryRefresh on GetxController {
  Timer? _mediaTimer;

  /// Schedules [reload] a minute before the earliest of [expiries].
  void refreshBeforeExpiry(
    Iterable<DateTime?> expiries,
    Future<void> Function() reload,
  ) {
    _mediaTimer?.cancel();
    final upcoming = [for (final at in expiries) ?at]..sort();
    if (upcoming.isEmpty) return;
    final wait = upcoming.first
        .subtract(const Duration(minutes: 1))
        .difference(DateTime.now());
    _mediaTimer = Timer(wait.isNegative ? Duration.zero : wait, reload);
  }

  @override
  void onClose() {
    _mediaTimer?.cancel();
    super.onClose();
  }
}
