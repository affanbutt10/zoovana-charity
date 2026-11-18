import 'dart:async';
import 'package:get/get.dart';
import '../../../data/models/feeding_checkout.dart';

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
  FeedingQuote? quote;
  String? quoteError;
  bool quoting = false;
  int? maxQuantity, maxLines;
  Timer? _debounce;
  int _revision = 0;
  bool get quoteReady =>
      !quoting && quoteError == null && quote?.matches(state.lines) == true;
  void _scheduleQuote() {
    _debounce?.cancel();
    final revision = ++_revision;
    quote = null;
    quoteError = null;
    quoting = state.lines.isNotEmpty;
    if (state.lines.isEmpty) {
      update();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => refreshQuote(revision),
    );
  }

  Future<void> refreshQuote([int? revision]) async {
    final version = revision ?? ++_revision;
    if (state.lines.isEmpty) return;
    quoting = true;
    update();
    try {
      final result = await repository.quoteBasket(state.lines);
      if (isClosed || version != _revision) return;
      quote = result;
      maxQuantity = result.maxQuantity;
      maxLines = result.maxLines;
      quoteError = null;
    } catch (e) {
      if (isClosed || version != _revision) return;
      final error = AppErrorMapper.map(e);
      quoteError = error.message;
      final max = error.details['max'];
      if (error.code == 'basket_quantity_invalid' && max is num) {
        maxQuantity = max.toInt();
        final id = error.details['package_id'];
        final item = state.packages.firstWhereOrNull((p) => p.id == id);
        if (item != null) {
          setQuantity(item, max.toInt());
          return;
        }
      }
      if (error.code == 'basket_too_many_items') {
        maxLines = (error.details['max_line_items'] as num?)?.toInt();
      }
      if (error.code == 'package_inactive' ||
          error.code == 'package_not_found') {
        final id = error.details['package_id'];
        final fresh = await repository.getPackages(state.campaign!.id);
        if (isClosed || version != _revision) return;
        final quantities = Map<String, int>.from(
          state.quantities,
        )..removeWhere((key, _) => key == id || !fresh.any((p) => p.id == key));
        state = state.copyWith(
          packages: fresh,
          quantities: quantities,
          selectedId: quantities.keys.firstOrNull,
          clearSelection: quantities.isEmpty,
        );
        _scheduleQuote();
        update();
        return;
      }
      if (error.code == 'program_not_found') Get.offAllNamed(AppRoutes.home);
    }
    if (version == _revision) {
      quoting = false;
      update();
    }
  }

  @override
  void onClose() {
    _revision++;
    _debounce?.cancel();
    super.onClose();
  }

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
      _scheduleQuote();
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
    _scheduleQuote();
    update();
  }

  void setQuantity(CharityPackage item, int value) {
    final quantities = {
      for (final line in state.lines) line.item.id: line.quantity,
    };
    if (value > 0 &&
        !quantities.containsKey(item.id) &&
        maxLines != null &&
        quantities.length >= maxLines!) {
      quoteError = 'Maximum $maxLines items per basket.';
      update();
      return;
    }
    if (value <= 0) {
      quantities.remove(item.id);
    } else {
      quantities[item.id] = maxQuantity == null
          ? value
          : value.clamp(1, maxQuantity!);
    }
    state = state.copyWith(
      quantities: quantities,
      selectedId: quantities.keys.firstOrNull,
      clearSelection: quantities.isEmpty,
    );
    _scheduleQuote();
    update();
  }

  void search(String query) {
    state = state.copyWith(query: query);
    update();
  }

  void continueToCheckout() {
    final campaign = state.campaign;
    final package = state.selected;
    if (campaign == null || package == null || !quoteReady) return;
    Get.toNamed(
      AppRoutes.checkout,
      arguments: {
        'campaign': campaign,
        'package': package,
        'lines': state.lines,
        'quote': quote,
      },
    );
  }
}
