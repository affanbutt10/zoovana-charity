import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/app_locale.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/donation_receipt.dart';
import '../../../routes/app_routes.dart';
import '../controllers/donation_history_controller.dart';

class DonationHistoryScreen extends GetView<DonationHistoryController> {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Your charity impact'.tr),
      body: controller.receipts.isEmpty
          ? const _EmptyHistory()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: controller.receipts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final card = DonationReceiptCard(
                  receipt: controller.receipts[index],
                );
                if (index >= 8) return card;
                return AppEntranceAnimation(
                  delay: AppMotion.stagger * math.min(index, 7),
                  duration: AppMotion.slow,
                  beginOffset: const Offset(0, .06),
                  child: card,
                );
              },
            ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppEntranceAnimation.pop(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.volunteer_activism_outlined,
                size: 54,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your charity journey starts here'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Completed contributions and their verified impact will appear here.'
                    .tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Charity request summary with its current donor-facing status.
class DonationReceiptCard extends StatelessWidget {
  const DonationReceiptCard({super.key, required this.receipt, this.onTap});
  final DonationReceipt receipt;

  /// Opens the request's progress; defaults to the request details route.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(Icons.favorite_rounded, color: AppColors.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DonationStatusPill(
                  status: receipt.status,
                  label: receipt.label,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  receipt.campaignTitle,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${receipt.packageName} · ${receipt.amountLabel}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  receipt.impact,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(receipt.createdAt)} · ${receipt.reference}',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
    return AppPressable(
      pressedScale: .98,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap:
            onTap ??
            () =>
                Get.toNamed<void>(AppRoutes.requestDetails, arguments: receipt),
        child: card,
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day} ${AppLocale.shortMonth(date.month)} ${date.year}';
}

/// Compact status badge: teal while in progress, green once completed and
/// coral when the request was closed without feeding.
class DonationStatusPill extends StatelessWidget {
  const DonationStatusPill({super.key, required this.status, this.label});
  final DonationStatus status;

  /// The API's localized label; the status only picks the colours.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      DonationStatus.completed => (
        const Color(0xFF2BB673),
        const Color(0xFFDDF5E8),
      ),
      DonationStatus.cancelled ||
      DonationStatus.refunded => (AppColors.accent, AppColors.accentSoft),
      DonationStatus.draft || DonationStatus.paymentPending => (
        const Color(0xFFB7791F),
        const Color(0xFFFFF4D2),
      ),
      _ => (AppColors.brand, const Color(0xFFCFEDE3)),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label ?? status.label.tr,
          style: TextStyle(
            color: foreground,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
