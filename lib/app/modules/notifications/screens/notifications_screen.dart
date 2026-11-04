import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/assets/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/models/app_notification.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../controllers/notifications_controller.dart';

/// Icon and tint for each `notification_type`.
(String, Color) _look(String type) => switch (type) {
  'payment_received' ||
  'payment_failed' ||
  'refund_issued' ||
  'payout_eligible' ||
  'payout_paid' => (AppIcons.notificationMoney, const Color(0xFFFEF8E8)),
  'proof_submitted' ||
  'proof_approved' ||
  'proof_rejected' ||
  'feeding_completed' => (AppIcons.notificationFolder, const Color(0xFFFFF1F4)),
  'feeder_approved' ||
  'feeder_rejected' => (AppIcons.notificationDoctor, const Color(0xFFF8EFFF)),
  _ => (AppIcons.notificationFood, const Color(0xFFEEF7F2)),
};

String _time(DateTime at) {
  final age = DateTime.now().difference(at);
  if (age.inHours < 24) {
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
  }
  return '@daysd ago'.trParams({'days': '${age.inDays}'});
}

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<NotificationsController>(
    builder: (controller) {
      final today = controller.today;
      final earlier = controller.earlier;
      return Scaffold(
        appBar: ZoovanaAppBar(title: 'Notifications'.tr),
        body: AppStateView(
          isLoading: controller.isLoading,
          error: controller.error,
          onRetry: controller.load,
          child: controller.items.isEmpty
              ? const _EmptyNotifications()
              : RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: controller.load,
                  child: NotificationListener<ScrollEndNotification>(
                    onNotification: (notification) {
                      final metrics = notification.metrics;
                      if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 23, 20, 32),
                      children: staggered([
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                today.isNotEmpty
                                    ? 'Today’s Notifications'.tr
                                    : 'Last 7 days'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AppPressable(
                              pressedScale: .94,
                              child: GestureDetector(
                                onTap: controller.markAllRead,
                                child: Text(
                                  'Mark all as read'.tr,
                                  style: const TextStyle(
                                    color: AppColors.brand,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.brand,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ..._cards(controller, today),
                        if (earlier.isNotEmpty) ...[
                          if (today.isNotEmpty) ...[
                            const SizedBox(height: 23),
                            Text(
                              'Earlier'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                          ..._cards(controller, earlier),
                        ],
                        if (controller.isLoadingMore)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
        ),
      );
    },
  );

  List<Widget> _cards(
    NotificationsController controller,
    List<AppNotification> list,
  ) => [
    for (final item in list)
      Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: _NotificationCard(
          item: item,
          onTap: () => controller.open(item),
        ),
      ),
  ];
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = _look(item.type);
    return SurfaceCard(
      radius: 10,
      shadow: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(13, 15, 13, 17),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 57,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(28),
            ),
            child: AssetIcon(icon, size: 22, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _time(item.createdAt),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 8,
            // Scaled to zero (painting nothing) once read.
            child: AnimatedScale(
              scale: item.isRead ? 0 : 1,
              duration: AppMotion.medium,
              curve: AppMotion.curve,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 176),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: staggered([
        Transform.translate(
          offset: const Offset(8, 0),
          child: Image.asset(AppAssets.emptyNotifications, height: 257),
        ),
        const SizedBox(height: 34),
        Text(
          'No Notification Yet'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21),
        ),
      ]),
    ),
  );
}
