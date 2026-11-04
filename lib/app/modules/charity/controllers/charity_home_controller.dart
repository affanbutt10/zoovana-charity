import 'package:get/get.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../routes/app_routes.dart';
import '../models/charity_home_state.dart';

class CharityHomeController extends GetxController {
  CharityHomeController({required this.repository});

  final CharityRepository repository;
  CharityHomeState state = const CharityHomeState();

  @override
  void onInit() {
    super.onInit();
    loadCampaigns();
  }

  Future<void> loadCampaigns({bool showLoading = true}) async {
    state = state.copyWith(isLoading: showLoading, clearError: true);
    update();
    try {
      final campaigns = await repository.getCampaigns();
      state = state.copyWith(
        isLoading: false,
        campaigns: campaigns,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: AppErrorMapper.map(error).message,
      );
    }
    update();
  }

  Future<void> refreshCampaigns() => loadCampaigns(showLoading: false);

  void openCampaign(CharityCampaign campaign) {
    Get.toNamed(AppRoutes.campaign, arguments: campaign);
  }

  void openHistory() => Get.toNamed(AppRoutes.history);
}
