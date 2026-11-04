import 'package:get/get.dart';

import '../../../data/repositories/charity_repository.dart';
import '../controllers/donation_history_controller.dart';

class DonationHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DonationHistoryController>(
      () =>
          DonationHistoryController(repository: Get.find<CharityRepository>()),
    );
  }
}
