import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../data/repositories/notification_repository.dart';
import '../../routes/app_routes.dart';
import 'zoovana_ui.dart';

/// Header bell with a dot while there are unread notifications.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, this.onReturn});

  /// Runs after the notification list closes, e.g. to refresh the shell.
  final VoidCallback? onReturn;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  bool hasUnread = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final count = await Get.find<NotificationRepository>().unreadCount();
      if (mounted) setState(() => hasUnread = count > 0);
    } catch (_) {
      // Keep the last known state; the bell still opens the list.
    }
  }

  @override
  Widget build(BuildContext context) => HeaderCircleButton(
    icon: Iconsax.notification_copy,
    tooltip: 'Notifications'.tr,
    badge: hasUnread,
    onTap: () async {
      await Get.toNamed<void>(AppRoutes.notifications);
      widget.onReturn?.call();
      await _refresh();
    },
  );
}
