import 'package:get/get.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/services/media_expiry.dart';
import '../../../core/services/mock_checkout.dart';
import '../../../data/models/charity_request_detail.dart';
import '../../../data/models/donation_receipt.dart';
import '../../../data/repositories/charity_repository.dart';

class RequestDetailsController extends GetxController with MediaExpiryRefresh {
  RequestDetailsController({required this.repository});

  final CharityRepository repository;

  /// The request UUID; the route takes a request or, from a deep link, its ID.
  String? requestId;
  CharityRequestDetail? detail;
  bool isLoading = true;
  bool isCancelling = false;
  String? error;

  bool get canCancel => detail?.status.isUnpaid ?? false;

  bool get canPay =>
      canCancel && AppConfig.enableMockCheckout && AppConfig.useRemoteApi;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    requestId = switch (argument) {
      DonationReceipt request => request.requestId,
      String id when id.isNotEmpty => id,
      _ => null,
    };
    if (requestId != null) {
      load();
    } else {
      isLoading = false;
      error = 'This request could not be found.'.tr;
    }
  }

  /// Fetches the latest progress; keeps the current detail visible while
  /// refreshing. Called on open, pull-to-refresh and matching notifications.
  Future<void> load() async {
    final id = requestId;
    if (id == null) return;
    isLoading = detail == null;
    error = null;
    update();
    try {
      detail = await repository.getRequestDetailById(id);
      refreshBeforeExpiry([
        for (final media in detail!.proof?.media ?? const <ProofMedia>[])
          media.expiresAt,
        for (final event in detail!.timeline)
          for (final media in event.media) media.expiresAt,
      ], load);
    } catch (exception) {
      error = AppErrorMapper.map(exception).message;
    }
    isLoading = false;
    update();
  }

  Future<void> cancel() async {
    final current = detail;
    if (current == null || isCancelling) return;
    isCancelling = true;
    update();
    try {
      detail = await repository.cancelRequest(current.request);
    } catch (exception) {
      Get.snackbar('Cancel request'.tr, AppErrorMapper.map(exception).message);
      await load();
    }
    isCancelling = false;
    update();
  }

  /// Dev/staging only: funds the draft through the mock checkout, then
  /// re-fetches once the donor is back in the app.
  Future<void> pay() async {
    final current = detail;
    if (current == null) return;
    try {
      final url = await repository.getCheckoutUrl(current.request);
      if (url != null) await launchMockCheckout(url);
    } catch (exception) {
      Get.snackbar('Checkout'.tr, AppErrorMapper.map(exception).message);
    }
    await load();
  }
}
