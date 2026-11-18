import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import '../../../../apis/core/api_response.dart';
import '../../../data/models/feeding_checkout.dart';
import '../../../core/services/feeding_payment.dart';
import '../../../core/services/app_locale.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/forms/input_rules.dart';
import '../../../core/forms/checkout_phone.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_package.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../home/screens/customer_shell_screen.dart';
import '../models/charity_checkout_state.dart';

/// Server quote → donor contact → idempotent basket → provider sheet → server confirmation.
class CharityCheckoutController extends GetxController {
  CharityCheckoutController({
    required this.repository,
    this.session,
    this.paymentLauncher = openFeedingPayment,
    this.pollInterval = const Duration(seconds: 2),
  });
  final Future<void> Function(FeedingPaymentIntent, String) paymentLauncher;
  final Duration pollInterval;

  final CharityRepository repository;
  final SessionRepository? session;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dedicationController = TextEditingController();
  final DateTime draftDate = DateTime.now();
  String paymentMethod = 'card';
  bool checkoutLoading = true;
  FeedingPaymentMethods? methods;
  String countryCode = 'PK';
  String? get internationalPhone =>
      CheckoutPhone.international(phoneController.text, countryCode);
  void selectPhoneCountry(String value) {
    countryCode = value;
    update();
  }

  void phoneChanged(String value) {
    if (value.trim().startsWith('+')) {
      try {
        final phone = CheckoutPhone.parse(value, countryCode);
        if (phone.isValidLength()) {
          countryCode = phone.isoCode.name;
          phoneController.value = TextEditingValue(
            text: phone.nsn,
            selection: TextSelection.collapsed(offset: phone.nsn.length),
          );
        }
      } catch (_) {}
    }
    update();
  }

  final feedingNotesController = TextEditingController();
  String? _attemptKey, _attemptBody;
  String? get attemptKey => _attemptKey;
  List<FeedingPaymentMethod> get availableMethods =>
      methods?.methods
          .where(
            (m) =>
                m.id != 'google_pay' &&
                m.id != 'google' &&
                m.platforms.contains(
                  defaultTargetPlatform == TargetPlatform.iOS
                      ? 'ios'
                      : 'android',
                ) &&
                const ['card', 'apple_pay', 'stc_pay'].contains(m.id),
          )
          .toList() ??
      [];
  bool get ready =>
      !checkoutLoading &&
      availableMethods.any((m) => m.id == paymentMethod) &&
      state?.quote?.matches(state!.items) == true &&
      methods!.currencies.contains(state!.quote!.currency);
  Future<void> loadCheckout() async {
    final current = state;
    if (current == null) return;
    checkoutLoading = true;
    update();
    try {
      final results = await Future.wait<Object>([
        repository.checkoutContact(),
        repository.paymentMethods(),
        repository.quoteBasket(current.items),
      ]);
      if (isClosed) return;
      final contact = results[0] as Map<String, dynamic>;
      if (nameController.text.isEmpty) {
        nameController.text = contact.str('full_name');
      }
      if (emailController.text.isEmpty) {
        emailController.text = contact.str('email');
      }
      if (phoneController.text.isEmpty) {
        phoneController.text = contact.str('phone_number');
      }
      if (contact.str('country_code').isNotEmpty) {
        countryCode = contact.str('country_code');
      }
      if (phoneController.text.isNotEmpty) phoneChanged(phoneController.text);
      methods = results[1] as FeedingPaymentMethods;
      paymentMethod = availableMethods.firstOrNull?.id ?? '';
      state = state?.copyWith(
        quote: results[2] as FeedingQuote,
        clearError: true,
      );
    } catch (e) {
      if (!isClosed) {
        state = state?.copyWith(error: AppErrorMapper.map(e).message);
      }
    }
    if (!isClosed) {
      checkoutLoading = false;
      update();
    }
  }

  void selectPaymentMethod(String value) {
    paymentMethod = value;
    update();
  }

  bool isAnonymous = false;
  bool notifyPush = true;
  bool notifyEmail = true;
  CharityCheckoutState? state;
  String? initializationError;
  String? detailsError;
  bool isOpeningCheckout = false;
  int currentStep = 2;

  static const dedicationLimit = 300;

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    final campaign = arguments is Map ? arguments['campaign'] : null;
    final package = arguments is Map ? arguments['package'] : null;
    if (campaign is CharityCampaign && package is CharityPackage) {
      final lines = arguments['lines'];
      state = CharityCheckoutState(
        campaign: campaign,
        package: package,
        quote: arguments['quote'] is FeedingQuote
            ? arguments['quote'] as FeedingQuote
            : null,
        lines: lines is List<DonationLine>
            ? List.unmodifiable(lines)
            : const [],
      );
    } else {
      initializationError =
          'Your selected charity package could not be found.'.tr;
    }
    nameController.text = session?.displayName ?? '';
    emailController.text = session?.email ?? '';
    loadCheckout();
  }

  bool get hasValidDonorDetails => _validate() == null;

  void toggleAnonymous() {
    isAnonymous = !isAnonymous;
    update();
  }

  void togglePush() {
    notifyPush = !notifyPush;
    update();
  }

  void toggleEmail() {
    notifyEmail = !notifyEmail;
    update();
  }

  String? _validate() {
    if (!InputRules.name(nameController.text)) {
      return 'Enter your full name.'.tr;
    }
    if (!InputRules.email(emailController.text)) {
      return 'Enter a valid email address.'.tr;
    }
    if (phoneController.text.trim().isNotEmpty && internationalPhone == null) {
      return 'Enter a valid phone number.'.tr;
    }
    if (feedingNotesController.text.trim().length > 500) {
      return 'Feeding notes must be 500 characters or fewer.'.tr;
    }
    if (dedicationController.text.length > dedicationLimit) {
      return 'Keep the dedication under @limit characters.'.trParams({
        'limit': '$dedicationLimit',
      });
    }
    return null;
  }

  void continueToReview() {
    if (state == null) return;
    detailsError = _validate();
    if (detailsError == null) currentStep = 3;
    update();
  }

  void backToDetails() {
    currentStep = 2;
    update();
  }

  String? _receiptBody;
  DateTime? retryAfter;
  Future<void> submit() async {
    final current = state;
    if (current == null || current.isSubmitting) return;
    if (retryAfter != null && DateTime.now().isBefore(retryAfter!)) {
      state = current.copyWith(
        error: 'Please wait @seconds seconds before trying again.'.trParams({
          'seconds': '${retryAfter!.difference(DateTime.now()).inSeconds + 1}',
        }),
      );
      update();
      return;
    }
    if (!ready) {
      state = current.copyWith(
        error: 'Refresh the quote and payment methods before continuing.'.tr,
      );
      update();
      return;
    }
    detailsError = _validate();
    if (detailsError != null) {
      update();
      return;
    }

    state = current.copyWith(isSubmitting: true, clearError: true);
    update();
    try {
      final donor = DonorDetails(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: internationalPhone ?? '',
        countryCode: countryCode,
        dedication: dedicationController.text.trim(),
        isAnonymous: isAnonymous,
        notifyPush: notifyPush,
        notifyEmail: notifyEmail,
      );
      final body = jsonEncode({
        'basket': basketSignature(current.items),
        'name': donor.fullName,
        'email': donor.email,
        'phone': donor.phoneNumber,
        'country': countryCode,
        'dedication': donor.dedication,
        'notes': feedingNotesController.text.trim(),
        'anonymous': isAnonymous,
        'push': notifyPush,
        'email_notify': notifyEmail,
        'locale': AppLocale.code,
      });
      if (_attemptBody != body) {
        _attemptBody = body;
        _attemptKey = const Uuid().v4();
      }
      // A failed payment retries the existing draft; a changed body creates a new attempt.
      var receipt = current.receipt;
      if (receipt == null || _receiptBody != body) {
        receipt = await repository.createBasket(
          lines: current.items,
          donor: donor,
          notes: feedingNotesController.text,
          key: _attemptKey!,
        );
        _receiptBody = body;
      }
      state = state?.copyWith(receipt: receipt);
      if (receipt.status.isUnpaid) await payReceipt();
      state = state?.copyWith(isSubmitting: false);
    } catch (error) {
      final mapped = AppErrorMapper.map(error);
      state = state!.copyWith(
        isSubmitting: false,
        error: mapped.message,
        fieldErrors: mapped.fieldErrors,
      );
      if (mapped.code == 'rate_limited' || mapped.statusCode == 429) {
        final value = mapped.details['retry_after'];
        final seconds = int.tryParse('$value');
        DateTime? date;
        if (seconds != null) {
          date = DateTime.now().add(Duration(seconds: seconds));
        } else if (value is String) {
          try {
            date = HttpDate.parse(value);
          } catch (_) {}
        }
        retryAfter = date;
        state = state?.copyWith(
          error: date == null
              ? mapped.message
              : 'Please wait @seconds seconds before trying again.'.trParams({
                  'seconds': '${date.difference(DateTime.now()).inSeconds + 1}',
                }),
        );
      }
      if (mapped.code == 'idempotency_key_reused') {
        _attemptKey = const Uuid().v4();
      }
      if (mapped.code == 'donor_details_required') {
        currentStep = 2;
      }
      if (const [
        'basket_quantity_invalid',
        'basket_too_many_items',
        'package_inactive',
        'package_not_found',
        'basket_mixed_programs',
        'basket_mixed_currency',
      ].contains(mapped.code)) {
        currentStep = 2;
        state = state?.copyWith(
          error:
              '${mapped.message} ${'Return to packages and refresh your basket.'.tr}',
        );
        methods = null;
      }
      if (mapped.code == 'program_not_found') Get.offAllNamed(AppRoutes.home);
      // Field problems are fixed on the details step.
      if (mapped.fieldErrors.isNotEmpty) currentStep = 2;
    }
    update();
  }

  Future<void> retryPayment() async {
    try {
      await payReceipt();
    } catch (e) {
      state = state?.copyWith(error: AppErrorMapper.map(e).message);
      update();
    }
  }

  Future<void> payReceipt() async {
    final receipt = state?.receipt;
    if (receipt == null || !receipt.status.isUnpaid || isOpeningCheckout) {
      return;
    }
    isOpeningCheckout = true;
    update();
    try {
      final latest = await repository.getRequestDetail(receipt);
      if (isClosed) return;
      state = state?.copyWith(receipt: latest.request);
      if (latest.request.paymentStatus == 'paid' ||
          !latest.request.status.isUnpaid) {
        return;
      }
      final intent = await repository.paymentIntent(receipt.requestId);
      await paymentLauncher(intent, paymentMethod);
      for (var i = 0; i < 8 && !isClosed; i++) {
        final detail = await repository.getRequestDetail(receipt);
        if (isClosed) return;
        state = state?.copyWith(receipt: detail.request);
        if (detail.request.paymentStatus == 'paid' ||
            detail.request.status.isFinal) {
          break;
        }
        await Future<void>.delayed(pollInterval);
      }
    } finally {
      if (!isClosed) {
        isOpeningCheckout = false;
        update();
      }
    }
  }

  void returnHome() => Get.offAllNamed(AppRoutes.home);

  /// Lands on the requests tab, where the new request shows its status.
  void returnToRequests() =>
      Get.offAllNamed(AppRoutes.home, arguments: CustomerTab.requests);

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    dedicationController.dispose();
    feedingNotesController.dispose();
    super.onClose();
  }
}
