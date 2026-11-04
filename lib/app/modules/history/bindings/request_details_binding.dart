import 'package:get/get.dart';

import '../../../data/repositories/charity_repository.dart';
import '../controllers/request_details_controller.dart';

class RequestDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RequestDetailsController>(
      () => RequestDetailsController(repository: Get.find<CharityRepository>()),
    );
  }
}
