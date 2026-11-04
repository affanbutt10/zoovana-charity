import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../controllers/charity_checkout_controller.dart';
import '../models/charity_checkout_state.dart';

class CharityCheckoutScreen extends GetView<CharityCheckoutController> {
  const CharityCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CharityCheckoutController>(
      builder: (controller) {
        final state = controller.state;
        if (state == null) {
          return Scaffold(
            appBar: const ZoovanaAppBar(title: ''),
            body: Center(
              child: Text(
                controller.initializationError ?? 'Donation unavailable'.tr,
              ),
            ),
          );
        }
        final receipt = state.receipt;
        if (receipt != null) {
          return SuccessView(
            title: 'Request created'.tr,
            message: receipt.status.isUnpaid
                ? 'Your request @reference is saved. It starts once it is '
                          'funded.'
                      .trParams({'reference': receipt.reference})
                : 'Your request @reference is on its way to a local operator. '
                          'We’ll let you know as it progresses.'
                      .trParams({'reference': receipt.reference}),
            actions: [
              if (controller.canOpenMockCheckout)
                PillButton(
                  label: 'Complete test payment'.tr,
                  isLoading: controller.isOpeningCheckout,
                  onPressed: controller.openMockCheckout,
                ),
              PillButton(
                label: 'View my requests'.tr,
                style: controller.canOpenMockCheckout
                    ? PillButtonStyle.muted
                    : PillButtonStyle.primary,
                onPressed: controller.returnToRequests,
              ),
            ],
          );
        }
        final review = controller.currentStep == 3;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        return Scaffold(
          appBar: ZoovanaAppBar(title: 'Street Animals Support'.tr),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
            children: staggered([
              Bleed(
                amount: 4,
                child: StepProgress(
                  step: controller.currentStep,
                  total: 3,
                  label: review ? 'Review'.tr : 'Your details'.tr,
                ),
              ),
              SizedBox(height: review ? 32 : 34),
              AnimatedSwitcher(
                duration: AppMotion.slow,
                switchInCurve: AppMotion.curve,
                switchOutCurve: AppMotion.curve,
                layoutBuilder: pinnedSwitcherLayout,
                transitionBuilder: (child, animation) {
                  // Next enters from the end side, Back from the start side.
                  final incoming = child.key == ValueKey(review);
                  final dx = (incoming == review ? .08 : -.08) * (rtl ? -1 : 1);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(dx, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(review),
                  child: !review
                      ? _DetailsStep(controller: controller, state: state)
                      : Transform.translate(
                          offset: Offset(rtl ? 4 : -4, 0),
                          child: _StreetReview(
                            controller: controller,
                            state: state,
                          ),
                        ),
                ),
              ),
              if (state.error != null && review) ...[
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
            ]),
          ),
          bottomNavigationBar: BottomActionBar(
            children: [
              PillButton(
                label: 'Back'.tr,
                style: PillButtonStyle.muted,
                onPressed: review ? controller.backToDetails : Get.back,
              ),
              PillButton(
                label: review ? 'Confirm request'.tr : 'Next'.tr,
                isLoading: state.isSubmitting,
                onPressed: review
                    ? controller.submit
                    : controller.continueToReview,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Donor contact details, dedication and notification choices.
class _DetailsStep extends StatelessWidget {
  const _DetailsStep({required this.controller, required this.state});
  final CharityCheckoutController controller;
  final CharityCheckoutState state;

  @override
  Widget build(BuildContext context) {
    final fields = state.fieldErrors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donor Details'.tr,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Full name'.tr,
          controller: controller.nameController,
          compact: true,
          icon: Iconsax.user_copy,
          hint: 'Enter your full name'.tr,
          errorText: fields['full_name'],
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Email'.tr,
          controller: controller.emailController,
          compact: true,
          icon: Iconsax.sms_copy,
          keyboardType: TextInputType.emailAddress,
          hint: 'name@example.com',
          errorText: fields['email'],
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Phone number'.tr,
          controller: controller.phoneController,
          compact: true,
          icon: Iconsax.call_copy,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          hint: '+92 3xx xxx xxxx',
          errorText: fields['phone_number'],
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Dedication'.tr,
          controller: controller.dedicationController,
          compact: true,
          required: false,
          icon: Iconsax.heart_copy,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              CharityCheckoutController.dedicationLimit,
            ),
          ],
          hint: 'Optional message, e.g. on behalf of a loved one'.tr,
          errorText: fields['dedication'],
        ),
        const SizedBox(height: 18),
        _Toggle(
          label: 'Hide my name from the operator report'.tr,
          value: controller.isAnonymous,
          onTap: controller.toggleAnonymous,
        ),
        _Toggle(
          label: 'Send me push updates'.tr,
          value: controller.notifyPush,
          onTap: controller.togglePush,
        ),
        _Toggle(
          label: 'Email me updates'.tr,
          value: controller.notifyEmail,
          onTap: controller.toggleEmail,
        ),
        if (controller.detailsError != null) ...[
          const SizedBox(height: 10),
          Text(
            controller.detailsError!,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
        if (state.error != null && fields.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(state.error!, style: const TextStyle(color: AppColors.danger)),
        ],
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: AppPressable(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(9, 8, 0, 8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: value ? AppColors.brandDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.brandDeep, width: 1.6),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(label, style: const TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// White card with a coral heading and divider, used by both review steps.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEDEDED)),
        child,
      ],
    ),
  );
}

class _StreetReview extends StatelessWidget {
  const _StreetReview({required this.controller, required this.state});
  final CharityCheckoutController controller;
  final CharityCheckoutState state;

  @override
  Widget build(BuildContext context) {
    final city = state.campaign.city;
    final package = state.package;
    return Column(
      children: [
        _ReviewCard(
          title: 'Donate Details'.tr,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 14, 3),
            child: Column(
              children: [
                _ReviewLine(
                  label: 'About Donate :'.tr,
                  value: 'Feeding Street animals'.tr,
                ),
                _ReviewLine(
                  label: 'Animals Type :'.tr,
                  value: state.campaign.animal,
                ),
                _ReviewLine(
                  label: 'Location :'.tr,
                  value: city.startsWith('City of')
                      ? city
                      : 'City of @city'.trParams({'city': city}),
                ),
                _ReviewLine(
                  label: 'Donor :'.tr,
                  value: controller.isAnonymous
                      ? 'Anonymous'.tr
                      : controller.nameController.text.trim(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _ReviewCard(
          title: 'Feeding Package :'.tr,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 90,
                    child: LocalOrNetworkImage(
                      package.imageUrl ?? package.image,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        package.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        package.impact.isEmpty ? package.food : package.impact,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA3A3A3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  package.priceLabel,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Text('Total value :'.tr, style: _totalStyle)),
            Text(package.priceLabel, style: _totalStyle),
          ],
        ),
      ],
    );
  }

  static const _totalStyle = TextStyle(
    color: AppColors.brand,
    fontSize: 19,
    fontWeight: FontWeight.w600,
  );
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 21),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    ),
  );
}

// Payments are out of scope for phase one: card, Apple Pay and Google Pay
// entry come back once a provider is chosen. Also the shelter review, whose
// flow is excluded from this app.
/*
class _PaymentStep extends StatelessWidget {
  const _PaymentStep({required this.controller, required this.state});
  final CharityCheckoutController controller;
  final CharityCheckoutState state;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Payment Method',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        _MethodRow(
          label: 'Pay with Card',
          bold: true,
          selected: state.paymentMethod == PaymentMethod.card,
          onTap: () => controller.selectPaymentMethod(PaymentMethod.card),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.paymentMethod == PaymentMethod.card) ...[
                const SizedBox(height: 15),
                _CardFields(controller: controller),
                const SizedBox(height: 18),
                AppPressable(
                  child: GestureDetector(
                    onTap: controller.toggleSaveCard,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 9),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: AppMotion.fast,
                            curve: AppMotion.curve,
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: controller.saveCard
                                  ? AppColors.brandDeep
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: AppColors.brandDeep,
                                width: 1.6,
                              ),
                            ),
                            child: controller.saveCard
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              'Save card details for later',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
              ] else
                const SizedBox(height: 10),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE6E6E6)),
        _MethodRow(
          label: 'Google Pay',
          badge: const _GooglePayBadge(),
          selected: state.paymentMethod == PaymentMethod.googlePay,
          onTap: () => controller.selectPaymentMethod(PaymentMethod.googlePay),
        ),
        const Divider(height: 1, color: Color(0xFFE6E6E6)),
        _MethodRow(
          label: 'Apple Pay',
          badge: const _ApplePayBadge(),
          selected: state.paymentMethod == PaymentMethod.applePay,
          onTap: () => controller.selectPaymentMethod(PaymentMethod.applePay),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(child: Text('Total value :', style: _totalStyle)),
            Text(
              '${formatAmount(state.package.amount)}SAR',
              style: _totalStyle,
            ),
          ],
        ),
      ],
    ),
  );

  static const _totalStyle = TextStyle(
    color: AppColors.brand,
    fontSize: 19,
    fontWeight: FontWeight.w600,
  );
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.bold = false,
    this.badge,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool bold;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AppPressable(
      pressedScale: .98,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: bold ? 28 : 58,
          child: Row(
            children: [
              if (badge != null) ...[badge!, const SizedBox(width: 12)],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: bold ? 15 : 16,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Radio extends StatelessWidget {
  const _Radio({this.selected = true});
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.fast,
    curve: AppMotion.curve,
    width: 17,
    height: 17,
    padding: const EdgeInsets.all(2.6),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.brand, width: 1.6),
    ),
    child: AnimatedScale(
      scale: selected ? 1 : 0,
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}

class _GooglePayBadge extends StatelessWidget {
  const _GooglePayBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F3F4),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'G',
            style: TextStyle(color: Color(0xFF4285F4)),
          ),
          TextSpan(
            text: 'Pay',
            style: TextStyle(color: Color(0xFF5F6368)),
          ),
        ],
      ),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _ApplePayBadge extends StatelessWidget {
  const _ApplePayBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 22,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(4),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: const FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apple, color: Colors.white, size: 12),
          Text(
            'Pay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Overlapping red and orange discs of the card network mark.
class _CardMark extends StatelessWidget {
  const _CardMark();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 34,
    height: 22,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          child: CircleAvatar(radius: 11, backgroundColor: Color(0xFFEB001B)),
        ),
        Positioned(
          right: 0,
          child: CircleAvatar(radius: 11, backgroundColor: Color(0xE6F79E1B)),
        ),
      ],
    ),
  );
}

class _CardFields extends StatelessWidget {
  const _CardFields({required this.controller});
  final CharityCheckoutController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      LabeledField(
        label: 'Card holder name',
        controller: controller.nameController,
        compact: true,
        hint: 'Enter card holder name',
      ),
      const SizedBox(height: 18),
      LabeledField(
        label: 'Card Number',
        controller: controller.cardNumberController,
        compact: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(19),
        ],
        hint: 'Enter Card Number e.g 1xxxx-xxxx',
        suffix: const Padding(
          padding: EdgeInsets.only(right: 14),
          child: _CardMark(),
        ),
      ),
      const SizedBox(height: 18),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LabeledField(
              label: 'Expiry (MM/YY)',
              controller: controller.expiryController,
              compact: true,
              keyboardType: TextInputType.datetime,
              hint: 'Enter Expiry',
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: LabeledField(
              label: 'CVV',
              controller: controller.cvvController,
              compact: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              hint: 'Enter CVV',
            ),
          ),
        ],
      ),
    ],
  );
}

class _FeedingLine extends StatelessWidget {
  const _FeedingLine({required this.line});
  final DonationLine line;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          line.item.image,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              line.item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              line.item.food,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFA3A3A3), fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatAmount(line.item.amount)} SAR',
            style: const TextStyle(
              color: AppColors.brand,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Qty: ${line.quantity}',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  );
}

class _ShelterReview extends StatelessWidget {
  const _ShelterReview({required this.controller, required this.state});
  final CharityCheckoutController controller;
  final CharityCheckoutState state;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _ReviewCard(
        title: 'Order Items :',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: Column(
            children: [
              for (final line in controller.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          line.item.image,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Text(
                          line.item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${line.quantity}*${formatAmount(line.item.amount)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${formatAmount(line.total)}SAR',
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      _ReviewCard(
        title: 'Payment method :',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      switch (state.paymentMethod) {
                        PaymentMethod.card => 'Pay with Card',
                        PaymentMethod.googlePay => 'Google Pay',
                        PaymentMethod.applePay => 'Apple Pay',
                      },
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const _Radio(),
                ],
              ),
              if (state.paymentMethod == PaymentMethod.card) ...[
                const SizedBox(height: 18),
                _OutlinedCardSummary(controller: controller),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

/// Read-only card details on the shelter review: outlined pills with the
/// label sitting on the border.
class _OutlinedCardSummary extends StatelessWidget {
  const _OutlinedCardSummary({required this.controller});
  final CharityCheckoutController controller;

  Widget _field(String label, TextEditingController text, String fallback) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
      borderSide: BorderSide(color: AppColors.borderField),
    );
    return TextField(
      controller: text,
      readOnly: true,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: fallback,
        hintStyle: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(15, 20, 15, 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _field('Name on card', controller.nameController, 'Name on card'),
      const SizedBox(height: 25),
      _field('Card number', controller.cardNumberController, '•••• ••••'),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: _field(
              'Expiry (MM/YY)',
              controller.expiryController,
              'MM/YY',
            ),
          ),
          const SizedBox(width: 15),
          Expanded(child: _field('CVV', controller.cvvController, '•••')),
        ],
      ),
    ],
  );
}
*/
