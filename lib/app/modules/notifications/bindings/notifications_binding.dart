import 'package:get/get.dart';

import '../../../core/services/deep_link_service.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsController>(
      () => NotificationsController(
        repository: Get.find<NotificationRepository>(),
        session: Get.find<SessionRepository>(),
        links: Get.find<DeepLinkService>(),
      ),
    );
  }
}
