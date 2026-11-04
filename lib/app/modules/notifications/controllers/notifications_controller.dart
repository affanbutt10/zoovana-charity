import 'package:get/get.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/services/deep_link_service.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/shell_router.dart';

class NotificationsController extends GetxController {
  NotificationsController({
    required this.repository,
    required this.session,
    required this.links,
  });

  final NotificationRepository repository;
  final SessionRepository session;
  final DeepLinkService links;

  List<AppNotification> items = const [];
  bool isLoading = true;
  bool hasMore = false;
  bool isLoadingMore = false;
  int _page = 1;
  String? error;

  List<AppNotification> get today {
    final now = DateTime.now();
    return [
      for (final item in items)
        if (now.difference(item.createdAt).inHours < 24) item,
    ];
  }

  List<AppNotification> get earlier {
    final now = DateTime.now();
    return [
      for (final item in items)
        if (now.difference(item.createdAt).inHours >= 24) item,
    ];
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading = items.isEmpty;
    error = null;
    update();
    try {
      final page = await repository.getPage();
      items = page.items;
      hasMore = page.meta.hasNext;
      _page = 1;
    } catch (exception) {
      error = AppErrorMapper.map(exception).message;
    }
    isLoading = false;
    update();
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore) return;
    isLoadingMore = true;
    update();
    try {
      final page = await repository.getPage(page: _page + 1);
      items = [...items, ...page.items];
      hasMore = page.meta.hasNext;
      _page++;
    } catch (_) {
      // The list keeps what it has; scrolling again retries.
    }
    isLoadingMore = false;
    update();
  }

  Future<void> markAllRead() async {
    items = [for (final item in items) item.read()];
    update();
    try {
      await repository.markAllRead();
    } catch (_) {
      await load();
    }
  }

  /// Marks [item] read and opens its target, which re-fetches itself.
  Future<void> open(AppNotification item) async {
    if (!item.isRead) {
      items = [
        for (final other in items) other.id == item.id ? item.read() : other,
      ];
      update();
      repository.markRead(item.id).ignore();
    }
    // An approval or rejection changes which screen the operator belongs on.
    if (item.type == 'feeder_approved' || item.type == 'feeder_rejected') {
      try {
        ShellRouter.open(await session.reload());
      } catch (exception) {
        Get.snackbar('Notifications'.tr, AppErrorMapper.map(exception).message);
      }
      return;
    }
    links.open(item.deepLink);
  }
}
