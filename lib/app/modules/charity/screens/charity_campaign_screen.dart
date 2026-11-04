import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/models/charity_package.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../controllers/charity_campaign_controller.dart';

class CharityCampaignScreen extends GetView<CharityCampaignController> {
  const CharityCampaignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CharityCampaignController>(
      builder: (controller) {
        final state = controller.state;
        return Scaffold(
          appBar: ZoovanaAppBar(title: 'Street Animals Support'.tr),
          body: AppStateView(
            isLoading: state.isLoading,
            error: state.error,
            onRetry: controller.loadPackages,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              children: [
                ...staggered([
                  Bleed(
                    amount: 4,
                    child: StepProgress(
                      step: 1,
                      total: 3,
                      label: 'Food Packages'.tr,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Choose one feeding package :'.tr,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SearchPill(hint: 'Search..'.tr, onChanged: controller.search),
                ]),
                const SizedBox(height: 14),
                for (final (index, item) in state.visiblePackages.indexed) ...[
                  _entrance(
                    key: ValueKey(item.id),
                    index: index,
                    child: _PackageCard(
                      item: item,
                      selected: item.id == state.selectedId,
                      onTap: () => controller.select(item),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (state.visiblePackages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        state.packages.isEmpty
                            ? 'No packages are available for this programme.'.tr
                            : 'No packages match your search.'.tr,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: state.isLoading || state.error != null
              ? null
              : BottomActionBar(
                  children: [
                    PillButton(
                      label: 'Next'.tr,
                      onPressed: state.selected == null
                          ? null
                          : controller.continueToCheckout,
                    ),
                  ],
                ),
        );
      },
    );
  }

  static Widget _entrance({
    required Key key,
    required int index,
    required Widget child,
  }) => index < 8
      ? AppEntranceAnimation(
          key: key,
          delay: AppMotion.stagger * (index + 1),
          duration: AppMotion.slow,
          beginOffset: const Offset(0, .06),
          child: child,
        )
      : KeyedSubtree(key: key, child: child);
}

/// One impact package: photo, meals, price and a selection mark.
class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CharityPackage item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.brand : Colors.transparent,
          width: 1.6,
        ),
      ),
      child: SurfaceCard(
        radius: 12,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 76,
                child: LocalOrNetworkImage(item.imageUrl ?? item.image),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.recommended) ...[
                    // A Row keeps the tag at its own width.
                    Row(
                      children: [
                        StatusTag(
                          label: 'Popular'.tr,
                          foreground: AppColors.accent,
                          background: AppColors.accentSoft,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.impact.isEmpty ? item.food : item.impact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFA3A3A3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.priceLabel,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.brand : AppColors.borderStrong,
            ),
          ],
        ),
      ),
    ),
  );
}
