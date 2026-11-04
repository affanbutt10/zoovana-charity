import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/charity_session.dart';
import '../../../routes/shell_router.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../controllers/operator_application_controller.dart';
import '../controllers/operator_status_controller.dart';

/// Full-page message with an icon, used by the status and unsupported
/// screens.
class _StatusPage extends StatelessWidget {
  const _StatusPage({
    required this.icon,
    required this.tint,
    required this.title,
    required this.message,
    required this.actions,
    this.detail,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String message;
  final String? detail;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const ZoovanaAppBar(title: '', showBack: false),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      children: staggered([
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: tint),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        if (detail != null && detail!.isNotEmpty) ...[
          const SizedBox(height: 20),
          SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail!,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        for (final action in actions) ...[action, const SizedBox(height: 12)],
      ]),
    ),
  );
}

/// The account signed in but has no Charity access (`app_mode: unsupported`
/// or `insufficient_role`).
class UnsupportedAccountScreen extends StatelessWidget {
  const UnsupportedAccountScreen({super.key});

  @override
  Widget build(BuildContext context) => _StatusPage(
    icon: Iconsax.shield_cross_copy,
    tint: AppColors.accent,
    title: 'This account can’t use the Charity app'.tr,
    message:
        'Sign in with a donor account, or with the operator account the '
                'Zoovana team created for you.'
            .tr,
    actions: [PillButton(label: 'Sign out'.tr, onPressed: ShellRouter.signOut)],
  );
}

/// Under review, rejected or suspended operator.
class OperatorStatusScreen extends StatelessWidget {
  const OperatorStatusScreen({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorStatusController>(
    builder: (controller) {
      final reason = controller.profile?.rejectionReason;
      final (icon, tint, title, message) = switch (controller.status) {
        VerificationStatus.rejected => (
          Iconsax.close_circle_copy,
          AppColors.accent,
          'Application not approved'.tr,
          'Your operator application wasn’t approved. Contact the Zoovana '
                  'team if you’d like to apply again.'
              .tr,
        ),
        VerificationStatus.suspended => (
          Iconsax.pause_circle_copy,
          AppColors.accent,
          'Account suspended'.tr,
          'Your operator account is paused, so you won’t get new tasks.'.tr,
        ),
        _ => (
          Iconsax.clock_copy,
          AppColors.brand,
          'Your application is under review'.tr,
          'We’re checking your documents. You’ll get a notification once '
                  'you’re approved.'
              .tr,
        ),
      };
      return AppStateView(
        isLoading: controller.isLoading,
        error: controller.profile == null ? controller.error : null,
        onRetry: controller.load,
        child: _StatusPage(
          icon: icon,
          tint: tint,
          title: title,
          message: message,
          detail: reason,
          actions: [
            PillButton(
              label: 'Check again'.tr,
              isLoading: controller.isChecking,
              onPressed: controller.checkAgain,
            ),
            PillButton(
              label: 'Sign out'.tr,
              style: PillButtonStyle.muted,
              onPressed: ShellRouter.signOut,
            ),
          ],
        ),
      );
    },
  );
}

/// Operator application (KYC). Operations creates the account; the operator
/// fills this in on first sign-in.
class OperatorApplicationScreen extends StatelessWidget {
  const OperatorApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      GetBuilder<OperatorApplicationController>(
        builder: (controller) => Scaffold(
          appBar: ZoovanaAppBar(
            title: 'Operator application'.tr,
            showBack: false,
          ),
          body: AppStateView(
            isLoading: controller.isLoading,
            error: controller.loadError,
            onRetry: controller.load,
            child: _ApplicationForm(controller: controller),
          ),
          bottomNavigationBar: controller.isLoading
              ? null
              : BottomActionBar(
                  children: [
                    PillButton(
                      label: 'Sign out'.tr,
                      style: PillButtonStyle.muted,
                      onPressed: ShellRouter.signOut,
                    ),
                    PillButton(
                      label: 'Submit'.tr,
                      isLoading: controller.isSubmitting,
                      onPressed: controller.submit,
                    ),
                  ],
                ),
        ),
      );
}

class _ApplicationForm extends StatelessWidget {
  const _ApplicationForm({required this.controller});
  final OperatorApplicationController controller;

  static const _heading = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    final fields = controller.fieldErrors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          'Tell us where you can feed and how we pay you. The team reviews '
                  'every application before you get tasks.'
              .tr,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 10),
        Text('Programme'.tr, style: _heading),
        const SizedBox(height: 8),
        LabeledDropdown(
          label: 'Feeding programme'.tr,
          options: [for (final program in controller.programs) program.title],
          value: controller.program?.title,
          onChanged: (title) => controller.selectProgram(
            controller.programs.firstWhere((item) => item.title == title),
          ),
        ),
        if (controller.zones.isNotEmpty) ...[
          const SizedBox(height: 10),
          FieldLabel('Zones you can cover'.tr, required: false),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final zone in controller.zones)
                FilterChip(
                  label: Text(zone.name),
                  selected: controller.selectedZones.contains(zone.id),
                  selectedColor: AppColors.brandSoft,
                  checkmarkColor: AppColors.brand,
                  onSelected: (_) => controller.toggleZone(zone.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tasks per day'.tr,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            QuantityStepper(
              count: controller.dailyCapacity,
              onChanged: (value) =>
                  controller.setCapacity(value < 1 ? 1 : value),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Your details'.tr, style: _heading),
        const SizedBox(height: 8),
        LabeledField(
          compact: true,
          label: 'Full name'.tr,
          controller: controller.nameController,
          icon: Iconsax.user_copy,
          errorText: fields['full_name'],
        ),
        const SizedBox(height: 10),
        LabeledField(
          compact: true,
          label: 'Phone number'.tr,
          controller: controller.phoneController,
          icon: Iconsax.call_copy,
          hint: '+966 5x xxx xxxx',
          keyboardType: TextInputType.phone,
          errorText: fields['phone_number'],
        ),
        const SizedBox(height: 10),
        LabeledField(
          compact: true,
          label: 'Email'.tr,
          controller: controller.emailController,
          icon: Iconsax.sms_copy,
          keyboardType: TextInputType.emailAddress,
          required: false,
          errorText: fields['email'],
        ),
        const SizedBox(height: 18),
        Text('Bank account'.tr, style: _heading),
        const SizedBox(height: 8),
        LabeledField(
          compact: true,
          label: 'Account holder name'.tr,
          controller: controller.holderController,
          icon: Iconsax.user_tag_copy,
          errorText: fields['bank_account_holder_name'],
        ),
        const SizedBox(height: 10),
        LabeledField(
          compact: true,
          label: 'Bank name'.tr,
          controller: controller.bankController,
          icon: Iconsax.bank_copy,
          errorText: fields['bank_name'],
        ),
        const SizedBox(height: 10),
        LabeledField(
          compact: true,
          label: 'IBAN'.tr,
          controller: controller.ibanController,
          icon: Iconsax.card_copy,
          hint: 'SA03 8000 0000 6080 1016 7519',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 ]')),
          ],
          errorText: fields['iban'],
        ),
        const SizedBox(height: 18),
        Text('Identity documents'.tr, style: _heading),
        const SizedBox(height: 12),
        // The three photos side by side keep the form short.
        Row(
          children: [
            for (final (index, document) in KycDocument.values.indexed) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(
                child: _DocumentTile(
                  document: document,
                  path: controller.documents[document],
                  onPick: () async {
                    final picked = await pickMedia(context);
                    if (picked != null) {
                      controller.setDocument(document, picked.path);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        if (controller.submitError != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.submitError!,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.path,
    required this.onPick,
  });

  final KycDocument document;
  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onPick,
    padding: const EdgeInsets.all(8),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (path == null)
                  const ColoredBox(
                    color: AppColors.surfaceSubtle,
                    child: Icon(Iconsax.camera_copy, color: AppColors.brand),
                  )
                else
                  LocalOrNetworkImage(path!),
                if (path != null)
                  const PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: Icon(
                      Iconsax.tick_circle,
                      color: Color(0xFF2BB673),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          document.label,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, height: 1.15),
        ),
      ],
    ),
  );
}
