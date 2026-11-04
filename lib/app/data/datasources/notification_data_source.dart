import 'package:dio/dio.dart';

import '../../../apis/core/api_client.dart';
import '../../../apis/core/api_endpoints.dart';
import '../../../apis/core/api_response.dart';
import '../models/app_notification.dart';

abstract interface class NotificationDataSource {
  Future<PagedList<AppNotification>> fetch({int page = 1, bool unreadOnly});

  Future<void> markRead(String id);

  Future<void> markAllRead();
}

class RemoteNotificationDataSource implements NotificationDataSource {
  RemoteNotificationDataSource(this._client);

  final ApiClient _client;
  Dio get _dio => _client.feeding;

  @override
  Future<PagedList<AppNotification>> fetch({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.notifications,
      queryParameters: {
        'page': page,
        'page_size': 20,
        'unread_only': unreadOnly,
      },
    );
    return response.paged(AppNotification.fromJson);
  }

  @override
  Future<void> markRead(String id) =>
      _dio.post<dynamic>(FeedingEndpoints.readNotification(id));

  @override
  Future<void> markAllRead() =>
      _dio.post<dynamic>(FeedingEndpoints.readAllNotifications);
}

class SeedNotificationDataSource implements NotificationDataSource {
  SeedNotificationDataSource({required this.operator});

  /// Which inbox the seed account gets, as the token decides on the server.
  final bool Function() operator;
  final _read = <String>{};

  List<AppNotification> get _items {
    final now = DateTime.now();
    final items = operator()
        ? [
            AppNotification(
              id: 'n-task',
              type: 'task_assigned',
              title: 'New feeding task',
              message: 'Feed Cats in Makkah · accept within 24 hours.',
              createdAt: now.subtract(const Duration(minutes: 19)),
              deepLink: 'zoovana-charity://operator/task/task-1001',
              targetId: 'task-1001',
            ),
            AppNotification(
              id: 'n-rejected',
              type: 'proof_rejected',
              title: 'Proof needs changes',
              message: 'Please upload a clearer feeding photo.',
              createdAt: now.subtract(const Duration(hours: 3)),
              deepLink: 'zoovana-charity://operator/task/task-1004',
              targetId: 'task-1004',
            ),
            AppNotification(
              id: 'n-payout',
              type: 'payout_paid',
              title: 'Payout sent',
              message: '15 SAR for ZF-0940 was paid.',
              createdAt: now.subtract(const Duration(days: 8)),
            ),
          ]
        : [
            AppNotification(
              id: 'n-welcome',
              type: 'payment_received',
              title: 'Welcome to Zoovana Charity',
              message: 'Choose a city and a package to fund a verified feeding round.',
              createdAt: now.subtract(const Duration(hours: 1)),
            ),
            AppNotification(
              id: 'n-how',
              type: 'feeding_completed',
              title: 'Proof you can see',
              message: 'Once a feeding is approved, its photos and impact appear in your request.',
              createdAt: now.subtract(const Duration(days: 2)),
            ),
          ];
    return [
      for (final item in items) _read.contains(item.id) ? item.read() : item,
    ];
  }

  @override
  Future<PagedList<AppNotification>> fetch({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    final items = [
      for (final item in _items)
        if (!unreadOnly || !item.isRead) item,
    ];
    return PagedList(items, PageMeta(total: items.length));
  }

  @override
  Future<void> markRead(String id) async => _read.add(id);

  @override
  Future<void> markAllRead() async => _read.addAll(_items.map((e) => e.id));
}
