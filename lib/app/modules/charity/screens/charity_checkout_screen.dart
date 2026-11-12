import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../controllers/charity_checkout_controller.dart';
import '../models/charity_checkout_state.dart';
import '../widgets/feeding_design_widgets.dart';

class CharityCheckoutScreen extends GetView<CharityCheckoutController> {
  const CharityCheckoutScreen({super.key});

  Future<void> _next(BuildContext context) async {
    if (controller.currentStep == 3) {
      await controller.submit();
      return;
    }
    if (controller.hasValidDonorDetails) {
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
        return SuccessView(
          title:
              (receipt.status.isUnpaid
                      ? 'Request created'
                      : 'Donation successful')
                  .tr,
          message: receipt.status.isUnpaid
              ? 'Your request @reference is saved. It starts once it is funded.'
                    .trParams({'reference': receipt.reference})
              : 'Your request @reference is on its way to a local operator. We’ll let you know as it progresses.'
                    .trParams({'reference': receipt.reference}),
          actions: [
            if (c.canOpenMockCheckout)
              PillButton(
                label: 'Complete test payment'.tr,
                isLoading: c.isOpeningCheckout,
                onPressed: c.openMockCheckout,
              ),
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
              label: 'Next'.tr,
              isLoading: state.isSubmitting,
              onPressed: () => _next(context),
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
      const SizedBox(height: 12),
      for (final method in const [
        ('card', 'Pay with Card'),
        ('google', 'Google Pay'),
        ('apple', 'Apple Pay'),
        ('wallet', 'E-WALLET'),
      ])
        Column(
          children: [
            Semantics(
              button: true,
              selected: controller.paymentMethod == method.$1,
              child: InkWell(
                onTap: () => controller.selectPaymentMethod(method.$1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: _PaymentBadge(method: method.$1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          method.$2.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _PaymentRadio(
                        selected: controller.paymentMethod == method.$1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (method.$1 != 'wallet')
              const Divider(height: 1, color: Color(0xFFEDEDE8)),
          ],
        ),
      const SizedBox(height: 24),
      if (controller.paymentMethod == 'card') ...[
        _PendingCardFields(
          onTap: () => Get.snackbar(
            'Payments'.tr,
            'Card payments are not available yet.'.tr,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: controller.toggleSaveCard,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.brand, width: 1.5),
                    color: controller.saveCard ? AppColors.brand : null,
                  ),
                  child: controller.saveCard
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Save card details for later'.tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
      Row(
        children: [
          Expanded(child: Text('Total value :'.tr, style: _totalStyle)),
          Text(state.totalLabel, style: _totalStyle),
        ],
      ),
    ],
  );
  static const _totalStyle = TextStyle(
    color: AppColors.brand,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
}

class _PendingCardFields extends StatelessWidget {
  const _PendingCardFields({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      // The gateway/tokenization contract is pending: fields match the reference
      // but cannot collect or store real card data in the interim.
      LabeledField(
        label: 'Card holder name'.tr,
        hint: 'Enter card holder name'.tr,
        readOnly: true,
        compact: true,
        onTap: onTap,
      ),
      const SizedBox(height: 18),
      LabeledField(
        label: 'Card Number'.tr,
        hint: 'Enter Card Number e.g 1xxxx-xxxx'.tr,
        readOnly: true,
        compact: true,
        onTap: onTap,
        suffix: const Padding(
          padding: EdgeInsetsDirectional.only(end: 14),
          child: _MastercardBadge(),
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
            child: LabeledField(
              label: 'Expiry (MM/YY)'.tr,
              hint: 'Enter Expiry'.tr,
              readOnly: true,
              compact: true,
              onTap: onTap,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: LabeledField(
              label: 'CVV'.tr,
              hint: 'Enter CVV'.tr,
              readOnly: true,
              compact: true,
              onTap: onTap,
            ),
          ),
        ],
      ),
    ],
  );
}

class _MastercardBadge extends StatelessWidget {
  const _MastercardBadge();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 24,
    child: Stack(
      children: [
        Container(
          width: 23,
          height: 23,
          decoration: const BoxDecoration(
            color: Color(0xFFEB001B),
            shape: BoxShape.circle,
          ),
        ),
        PositionedDirectional(
          start: 13,
          child: Container(
            width: 23,
            height: 23,
            decoration: BoxDecoration(
              color: const Color(0xFFF79E1B).withValues(alpha: .95),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PaymentRadio extends StatelessWidget {
  const _PaymentRadio({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.brand, width: 1.7),
    ),
    child: selected
        ? Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
            ),
          )
        : null,
  );
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});
  final String method;
  @override
  Widget build(BuildContext context) => switch (method) {
    'google' => Container(
      height: 26,
      alignment: Alignment.center,
      color: const Color(0xFFF0F4FF),
      child: const FittedBox(fit: BoxFit.scaleDown, child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' Pay'),
          ],
        ),
        style: TextStyle(fontSize: 13),
      )),
    ),
    'apple' => Container(
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(3),
      ),
      child: const FittedBox(fit: BoxFit.scaleDown, child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apple, size: 15, color: Colors.white),
          Text('Pay', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      )),
    ),
    _ => const Icon(Icons.credit_card_outlined, size: 27),
  };
}

class _FeedingReview extends StatelessWidget {
  const _FeedingReview({required this.controller, required this.state});
  final CharityCheckoutController controller;
  final CharityCheckoutState state;
  String get _method => switch (controller.paymentMethod) {
    'google' => 'Google Pay',
    'apple' => 'Apple Pay',
    'wallet' => 'E-WALLET',
    _ => 'Card',
  };
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
                for (final line in state.items)
                  FeedingItemRow(
                    name: line.item.name,
                    image: line.item.imageUrl ?? line.item.image,
                    description: line.item.food,
                    amount: line.item.priceLabel,
                    quantity: line.quantity,
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
      LabeledField(
        label: 'Phone number'.tr,
        controller: controller.phoneController,
        keyboardType: TextInputType.phone,
        hint: '+92 3xx xxx xxxx',
        errorText: controller.state?.fieldErrors['phone_number'],
        compact: true,
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
