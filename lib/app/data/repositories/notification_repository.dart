import '../../../apis/core/api_response.dart';
import '../datasources/notification_data_source.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._dataSource);

  final NotificationDataSource _dataSource;

  Future<PagedList<AppNotification>> getPage({int page = 1}) =>
      _dataSource.fetch(page: page);

  Future<int> unreadCount() async =>
      (await _dataSource.fetch(unreadOnly: true)).meta.total;

  Future<void> markRead(String id) => _dataSource.markRead(id);

  Future<void> markAllRead() => _dataSource.markAllRead();
}
