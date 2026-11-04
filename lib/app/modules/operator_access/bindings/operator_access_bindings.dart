import 'package:get/get.dart';

import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/feeder_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../controllers/operator_application_controller.dart';
import '../controllers/operator_status_controller.dart';

class OperatorApplicationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorApplicationController>(
      () => OperatorApplicationController(
        charity: Get.find<CharityRepository>(),
        feeder: Get.find<FeederRepository>(),
        session: Get.find<SessionRepository>(),
      ),
    );
  }
}

class OperatorStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OperatorStatusController>(
      () => OperatorStatusController(
        feeder: Get.find<FeederRepository>(),
        session: Get.find<SessionRepository>(),
      ),
    );
  }
}
