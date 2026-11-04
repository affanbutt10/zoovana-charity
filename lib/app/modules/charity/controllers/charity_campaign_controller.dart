import 'package:get/get.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_package.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../routes/app_routes.dart';
import '../models/charity_campaign_state.dart';

class CharityCampaignController extends GetxController {
  CharityCampaignController({required this.repository});

  final CharityRepository repository;
  CharityCampaignState state = const CharityCampaignState();

  @override
  void onInit() {
    super.onInit();
    final campaign = Get.arguments;
    if (campaign is! CharityCampaign) {
      state = state.copyWith(
        isLoading: false,
        error: 'This charity campaign is no longer available.',
      );
      return;
    }
    state = state.copyWith(campaign: campaign);
    loadPackages();
  }

  Future<void> loadPackages() async {
    final campaign = state.campaign;
    if (campaign == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    update();
    try {
      final packages = await repository.getPackages(campaign.id);
      final popular =
          packages.firstWhereOrNull((item) => item.recommended) ??
          packages.firstOrNull;
      state = state.copyWith(
        isLoading: false,
        packages: packages,
        selectedId: popular?.id,
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

  void select(CharityPackage item) {
    state = state.copyWith(selectedId: item.id);
    update();
  }

  void search(String query) {
    state = state.copyWith(query: query);
    update();
  }

  void continueToCheckout() {
    final campaign = state.campaign;
    final package = state.selected;
    if (campaign == null || package == null) return;
    Get.toNamed(
      AppRoutes.checkout,
      arguments: {'campaign': campaign, 'package': package},
    );
  }
}
