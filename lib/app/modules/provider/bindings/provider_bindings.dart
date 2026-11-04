import 'package:get/get.dart';

import '../../../core/services/location_service.dart';
import '../../../data/repositories/feeder_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../controllers/operator_payouts_controller.dart';
import '../controllers/operator_shell_controller.dart';
import '../controllers/operator_task_controller.dart';

class OperatorShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorShellController>(
      () => OperatorShellController(
        repository: Get.find<FeederRepository>(),
        session: Get.find<SessionRepository>(),
      ),
    );
  }
}

class OperatorTaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorTaskController>(
      () => OperatorTaskController(
        repository: Get.find<FeederRepository>(),
        location: Get.isRegistered<LocationService>()
            ? Get.find<LocationService>()
            : LocationService(),
      ),
    );
  }
}

class OperatorPayoutsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorPayoutsController>(
      () => OperatorPayoutsController(repository: Get.find<FeederRepository>()),
    );
  }
}
