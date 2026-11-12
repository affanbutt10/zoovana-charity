import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/forms/input_rules.dart';
import '../../../core/services/mock_checkout.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_package.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../home/screens/customer_shell_screen.dart';
import '../models/charity_checkout_state.dart';

/// Donor details → review → `POST /requests`. Card entry is out of scope for
/// phase one; new requests start as drafts.
class CharityCheckoutController extends GetxController {
  CharityCheckoutController({required this.repository, this.session});

  final CharityRepository repository;
  final SessionRepository? session;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final dedicationController = TextEditingController();
  final DateTime draftDate = DateTime.now();
  String paymentMethod = 'card';
  bool saveCard = false;
  void selectPaymentMethod(String value) {
    paymentMethod = value;
    update();
  }

  void toggleSaveCard() {
    saveCard = !saveCard;
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
    _prefillContact();
  }

  Future<void> _prefillContact() async {
    try {
      final account = await session?.donorAccount();
      if (isClosed || account == null) return;
      if (phoneController.text.isEmpty) {
        phoneController.text = account.phoneNumber;
      }
      update();
    } catch (_) {
      /* Existing contact inputs remain available. */
    }
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
    if (!InputRules.phone(phoneController.text)) {
      return 'Enter a valid phone number.'.tr;
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

  Future<void> submit() async {
    final current = state;
    if (current == null || current.isSubmitting) return;
    if (!current.canSubmitLegacyRequest || current.hasMixedCurrencies) {
      state = current.copyWith(
        error:
            'Multiple items and quantities are not available for checkout yet.'
                .tr,
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
      final receipt = await repository.createRequest(
        campaign: current.campaign,
        package: current.items.single.item,
        donor: DonorDetails(
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          dedication: dedicationController.text.trim(),
          isAnonymous: isAnonymous,
          notifyPush: notifyPush,
          notifyEmail: notifyEmail,
        ),
      );
      state = current.copyWith(isSubmitting: false, receipt: receipt);
    } catch (error) {
      final mapped = AppErrorMapper.map(error);
      state = current.copyWith(
        isSubmitting: false,
        error: mapped.message,
        fieldErrors: mapped.fieldErrors,
      );
      // Field problems are fixed on the details step.
      if (mapped.fieldErrors.isNotEmpty) currentStep = 2;
    }
    update();
  }

  /// Dev/staging only: funds the draft through the backend's mock checkout,
  /// then re-fetches it so the screen shows whether the payment went through.
  bool get canOpenMockCheckout =>
      AppConfig.enableMockCheckout &&
      AppConfig.useRemoteApi &&
      (state?.receipt?.status.isUnpaid ?? false);

  Future<void> openMockCheckout() async {
    final receipt = state?.receipt;
    if (receipt == null) return;
    isOpeningCheckout = true;
    update();
    try {
      final url = await repository.getCheckoutUrl(receipt);
      if (url == null) {
        Get.snackbar('Checkout'.tr, 'No test checkout is available.'.tr);
      } else {
        await launchMockCheckout(url);
        final detail = await repository.getRequestDetail(receipt);
        state = state?.copyWith(receipt: detail.request);
      }
    } catch (error) {
      Get.snackbar('Checkout'.tr, AppErrorMapper.map(error).message);
    }
    isOpeningCheckout = false;
    update();
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
    super.onClose();
  }
}
