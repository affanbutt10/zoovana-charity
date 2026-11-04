import '../../../apis/core/api_response.dart';
import '../../core/services/app_locale.dart';

/// An inbox item. The same endpoints serve both shells; the token decides
/// whose inbox comes back.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.deepLink,
    this.targetId,
    this.isRead = false,
  });

  final String id;

  /// `notification_type`, e.g. `feeding_completed` or `task_assigned`.
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? deepLink;
  final String? targetId;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json.str('id'),
        type: json.str('notification_type'),
        title: AppLocale.pick(
          json.strOrNull('title_en') ?? json.strOrNull('title'),
          json.strOrNull('title_ar'),
          json.strOrNull('title_ur'),
        ),
        message: AppLocale.pick(
          json.strOrNull('message_en') ??
              json.strOrNull('message') ??
              json.strOrNull('body'),
          json.strOrNull('message_ar'),
          json.strOrNull('message_ur'),
        ),
        createdAt: json.time('created_at') ?? DateTime.now(),
        deepLink: json.strOrNull('deep_link'),
        targetId: json.strOrNull('target_id'),
        isRead: json.flag('is_read'),
      );

  AppNotification read() => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    createdAt: createdAt,
    deepLink: deepLink,
    targetId: targetId,
    isRead: true,
  );
}
