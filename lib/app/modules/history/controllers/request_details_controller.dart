import 'package:get/get.dart';

import 'package:flutter/foundation.dart';
import '../../../core/services/feeding_payment.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/services/media_expiry.dart';
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

  bool get canPay => canCancel;

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

  final Set<String> _failedUrls = {};
  bool _refreshingMedia = false;
  Future<void> refreshFailedMedia(String url) async {
    if (isClosed || _refreshingMedia || !_failedUrls.add(url)) return;
    _refreshingMedia = true;
    try {
      await load();
    } finally {
      _refreshingMedia = false;
    }
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

  bool isPaying = false;
  Future<void> pay() async {
    final current = detail;
    if (current == null || isPaying) return;
    isPaying = true;
    update();
    try {
      await load();
      if (isClosed || detail?.request.paymentStatus == 'paid' || detail?.status.isUnpaid != true) return;
      final methods = await repository.paymentMethods();
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final method = methods.methods
          .where((m) => m.id == 'card' && m.platforms.contains(platform))
          .firstOrNull;
      if (method == null) throw ArgumentError('Card payment is unavailable.');
      final intent = await repository.paymentIntent(current.request.requestId);
      await openFeedingPayment(intent, method.id);
      for (var i = 0; i < 8 && !isClosed; i++) {
        await load();
        if (detail?.request.paymentStatus == 'paid' ||
            detail?.status.isFinal == true) {
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      Get.snackbar('Checkout'.tr, AppErrorMapper.map(e).message);
    } finally {
      if (!isClosed) {
        isPaying = false;
        update();
      }
    }
  }
}
