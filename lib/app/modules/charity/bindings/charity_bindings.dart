import 'package:get/get.dart';

import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../controllers/charity_campaign_controller.dart';
import '../controllers/charity_checkout_controller.dart';
import '../controllers/charity_home_controller.dart';

class CharityHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CharityHomeController>(
      () => CharityHomeController(repository: Get.find<CharityRepository>()),
    );
  }
}

class CharityCampaignBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CharityCampaignController>(
      () =>
          CharityCampaignController(repository: Get.find<CharityRepository>()),
    );
  }
}

class CharityCheckoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CharityCheckoutController>(
      () => CharityCheckoutController(
        repository: Get.find<CharityRepository>(),
        session: Get.find<SessionRepository>(),
      ),
    );
  }
}
