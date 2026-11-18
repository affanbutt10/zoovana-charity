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
  bool gridView = false;

  void toggleLayout(bool grid) {
    gridView = grid;
    update();
  }

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
        quantities: popular == null ? const {} : {popular.id: 1},
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
    state = state.copyWith(selectedId: item.id, quantities: {item.id: 1});
    update();
  }

  void setQuantity(CharityPackage item, int value) {
    final quantities = {
      for (final line in state.lines) line.item.id: line.quantity,
    };
    if (value <= 0) {
      quantities.remove(item.id);
    } else {
      quantities[item.id] = value.clamp(1, 99);
    }
    state = state.copyWith(
      quantities: quantities,
      selectedId: quantities.keys.firstOrNull,
      clearSelection: quantities.isEmpty,
    );
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
      arguments: {
        'campaign': campaign,
        'package': package,
        'lines': state.lines,
      },
    );
  }
}
