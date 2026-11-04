import 'package:get/get.dart';

import '../../../data/models/charity_package.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../data/models/feeder_models.dart';
import '../../../data/repositories/feeder_repository.dart';

/// Read-only payout history; finance handles payouts in the CMS.
class OperatorPayoutsController extends GetxController {
  OperatorPayoutsController({required this.repository});

  final FeederRepository repository;

  /// Null lists every status.
  PayoutStatus? filter;
  List<FeederPayout> payouts = const [];

  /// Sum per status from `meta.totals`, e.g. `{"eligible": "30 SAR"}`.
  Map<String, String> totals = const {};
  bool isLoading = true;
  String? error;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading = payouts.isEmpty;
    error = null;
    update();
    try {
      final page = await repository.getPayouts(status: filter?.name);
      payouts = page.items;
      totals = {
        for (final entry in page.meta.totals.entries)
          entry.key: switch (entry.value) {
            // Either one amount, or one amount per currency.
            final Map<dynamic, dynamic> byCurrency =>
              byCurrency.entries
                  .map((item) => formatMoney('${item.value}', '${item.key}'))
                  .join(' · '),
            final value => formatMoney('$value', ''),
          },
      };
    } catch (exception) {
      error = AppErrorMapper.map(exception).message;
    }
    isLoading = false;
    update();
  }

  void select(PayoutStatus? value) {
    filter = value;
    payouts = const [];
    load();
  }
}
