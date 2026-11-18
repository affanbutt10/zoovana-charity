import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../apis/core/api_response.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../../shared/widgets/country_phone_field.dart';
import '../../../shared/widgets/donor_shimmers.dart';
import '../controllers/charity_checkout_controller.dart';
import '../models/charity_checkout_state.dart';
import '../widgets/feeding_design_widgets.dart';

class CharityCheckoutScreen extends GetView<CharityCheckoutController> {
  const CharityCheckoutScreen({super.key});

  Future<void> _next(BuildContext context, {bool editContact = false}) async {
    if (controller.currentStep == 3 && !editContact) {
      await controller.submit();
      return;
    }
    if (!controller.ready) return;
    if (controller.hasValidDonorDetails && !editContact) {
      controller.continueToReview();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceBase,
      builder: (context) => GetBuilder<CharityCheckoutController>(
        builder: (c) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DonorContactFields(controller: c),
                const SizedBox(height: 18),
                PillButton(
                  label: 'Continue'.tr,
                  onPressed: () {
                    c.continueToReview();
                    if (c.currentStep == 3) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => GetBuilder<CharityCheckoutController>(
    builder: (c) {
      final state = c.state;
      if (state == null) {
        return Scaffold(
          appBar: ZoovanaAppBar(title: 'Street Animals Support'.tr),
          body: Center(
            child: Text(c.initializationError ?? 'Donation unavailable'.tr),
          ),
        );
      }
      final receipt = state.receipt;
      if (receipt != null) {
        final paid = receipt.paymentStatus == 'paid';
        if (!paid) {
          return Scaffold(
            appBar: ZoovanaAppBar(title: 'Payment pending'.tr),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    size: 48,
                    color: AppColors.brand,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your request is awaiting payment confirmation.'.tr,
                    textAlign: TextAlign.center,
                  ),
                  Text(receipt.reference, textAlign: TextAlign.center),
                  if (state.error != null) Text(state.error!),
                  const SizedBox(height: 20),
                  if (receipt.status.isUnpaid)
                    PillButton(
                      label: 'Continue payment'.tr,
                      isLoading: c.isOpeningCheckout || state.isSubmitting,
                      onPressed: c.isOpeningCheckout || state.isSubmitting
                          ? null
                          : c.retryPayment,
                    ),
                  PillButton(
                    label: 'View my requests'.tr,
                    onPressed: c.returnToRequests,
                  ),
                ],
              ),
            ),
          );
        }
        return SuccessView(
          title: 'Donation successful'.tr,
          message:
              'Your request @reference is on its way to a local operator. We’ll let you know as it progresses.'
                  .trParams({'reference': receipt.reference}),
          actions: [
            PillButton(label: 'Back to Charity'.tr, onPressed: c.returnHome),
          ],
        );
      }
      final review = c.currentStep == 3;
      return Scaffold(
        appBar: ZoovanaAppBar(title: 'Street Animals Support'.tr),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
          children: [
            Bleed(
              amount: 4,
              child: FeedingStepProgress(
                step: c.currentStep,
                label: (review ? 'Review' : 'Payment Method').tr,
              ),
            ),
            const SizedBox(height: 34),
            if (!c.checkoutLoading)
              TextButton(
                onPressed: () => _next(context, editContact: true),
                child: Text('Edit donor details'.tr),
              ),
            if (review)
              _FeedingReview(controller: c, state: state)
            else
              _PaymentMethods(controller: c, state: state),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 14),
                ),
              ),
          ],
        ),
        bottomNavigationBar: BottomActionBar(
          children: [
            PillButton(
              label: 'Back'.tr,
              style: PillButtonStyle.muted,
              onPressed: state.isSubmitting
                  ? null
                  : review
                  ? c.backToDetails
                  : Get.back,
            ),
            PillButton(
              label: (review ? 'Pay / Confirm' : 'Next').tr,
              isLoading: state.isSubmitting || c.checkoutLoading,
              onPressed: c.ready && !state.isSubmitting
                  ? () => _next(context)
                  : null,
            ),
          ],
        ),
      );
    },
  );
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({required this.controller, required this.state});
  final CharityCheckoutController controller;
  final CharityCheckoutState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Choose Payment Method'.tr,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
      if (controller.checkoutLoading) const _PaymentMethodsShimmer(),
      for (final method in controller.availableMethods) ...[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            method.id == 'apple_pay'
                ? Icons.apple
                : method.id == 'stc_pay'
                ? Icons.account_balance_wallet_outlined
                : Icons.credit_card_outlined,
          ),
          title: Text(method.label.tr),
          trailing: Icon(
            controller.paymentMethod == method.id
                ? Icons.radio_button_checked
                : Icons.radio_button_off,
            color: AppColors.brand,
            size: 20,
          ),
          onTap: () => controller.selectPaymentMethod(method.id),
        ),
        const Divider(height: 1),
      ],
      if (!controller.checkoutLoading &&
          state.quote != null &&
          controller.methods != null &&
          !controller.methods!.currencies.contains(state.quote!.currency))
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Payments are currently unavailable for @currency. Please try again later.'
                .trParams({'currency': state.quote!.currency}),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      if (!controller.checkoutLoading && !controller.ready)
        TextButton(
          onPressed: controller.loadCheckout,
          child: Text('Refresh checkout'.tr),
        ),
      const SizedBox(height: 24),
      Text(
        'Payment details are entered securely with the payment provider.'.tr,
      ),
      const SizedBox(height: 24),
      LabeledField(
        label: 'Feeding notes'.tr,
        controller: controller.feedingNotesController,
        required: false,
        inputFormatters: [LengthLimitingTextInputFormatter(500)],
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: Text(
              'Total value :'.tr,
              style: const TextStyle(fontSize: 20, color: AppColors.brand),
            ),
          ),
          Flexible(
            child: Text(
              state.totalLabel,
              style: const TextStyle(fontSize: 20, color: AppColors.brand),
            ),
          ),
        ],
      ),
    ],
  );
}

class _FeedingReview extends StatelessWidget {
  const _FeedingReview({required this.controller, required this.state});
  final CharityCheckoutController controller;
  final CharityCheckoutState state;
  String get _method =>
      controller.availableMethods
          .where((m) => m.id == controller.paymentMethod)
          .firstOrNull
          ?.label ??
      '';
  @override
  Widget build(BuildContext context) {
    final date = controller.draftDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeedingSectionCard(
          title: 'Donate Details :',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Column(
              children: [
                FeedingInfoRow(
                  label: 'Donate Type',
                  value: 'Feeding Street animals'.tr,
                  divider: true,
                ),
                FeedingInfoRow(
                  label: 'Donate Date',
                  value: '${date.day}-${date.month}-${date.year}',
                  divider: true,
                ),
                FeedingInfoRow(
                  label: 'Donate Support',
                  value: state.campaign.animal,
                  divider: true,
                ),
                FeedingInfoRow(
                  label: 'Donate Location',
                  value: 'City of @city'.trParams({
                    'city': state.campaign.city,
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FeedingSectionCard(
          title: 'Feeding Items :',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Column(
              children: [
                for (final line
                    in state.quote?.items ?? <Map<String, dynamic>>[])
                  FeedingItemRow(
                    name: line.str('name'),
                    image: line.strOrNull('image_url') ?? '',
                    description: line.str('description'),
                    amount:
                        '${(line.integer('unit_amount_minor') / 100).toStringAsFixed(2)} ${line.str('currency')}',
                    quantity: line.integer('quantity'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FeedingSectionCard(
          title: 'Payment Summary',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            child: Column(
              children: [
                FeedingInfoRow(
                  label: 'Payment Method',
                  value: _method.tr,
                  divider: true,
                ),
                FeedingInfoRow(label: 'Item Total', value: state.totalLabel),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBase,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Total to Pay'.tr,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              state.totalLabel,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 24,
                                color: AppColors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Payment pending'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DonorContactFields extends StatelessWidget {
  const _DonorContactFields({required this.controller});
  final CharityCheckoutController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Donor Details'.tr,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 16),
      LabeledField(
        label: 'Full name'.tr,
        controller: controller.nameController,
        errorText: controller.state?.fieldErrors['full_name'],
        compact: true,
      ),
      const SizedBox(height: 14),
      LabeledField(
        label: 'Email'.tr,
        controller: controller.emailController,
        keyboardType: TextInputType.emailAddress,
        errorText: controller.state?.fieldErrors['email'],
        compact: true,
      ),
      const SizedBox(height: 14),
      CountryPhoneField(
        controller: controller.phoneController,
        countryCode: controller.countryCode,
        onCountryChanged: controller.selectPhoneCountry,
        onChanged: controller.phoneChanged,
        errorText: controller.state?.fieldErrors['phone_number'],
      ),
      const SizedBox(height: 14),
      LabeledField(
        label: 'Dedication'.tr,
        controller: controller.dedicationController,
        required: false,
        compact: true,
        inputFormatters: [
          LengthLimitingTextInputFormatter(
            CharityCheckoutController.dedicationLimit,
          ),
        ],
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: controller.isAnonymous,
        onChanged: (_) => controller.toggleAnonymous(),
        title: Text('Hide my name from the operator report'.tr),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: controller.notifyPush,
        onChanged: (_) => controller.togglePush(),
        title: Text('Send me push updates'.tr),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: controller.notifyEmail,
        onChanged: (_) => controller.toggleEmail(),
        title: Text('Email me updates'.tr),
      ),
      if (controller.detailsError != null)
        Text(
          controller.detailsError!,
          style: const TextStyle(color: AppColors.danger),
        ),
    ],
  );
}

class _PaymentMethodsShimmer extends StatelessWidget {
  const _PaymentMethodsShimmer();
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Container(width: 28, height: 24, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(child: Container(height: 16, color: Colors.white)),
                const SizedBox(width: 30),
                Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
