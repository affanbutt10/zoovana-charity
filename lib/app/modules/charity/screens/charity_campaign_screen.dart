import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/charity_package.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/donor_shimmers.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../controllers/charity_campaign_controller.dart';
import '../widgets/feeding_design_widgets.dart';

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
            loadingChild: controller.gridView
                ? const PackageGridShimmer()
                : const PackageListShimmer(),
            error: state.error,
            onRetry: controller.loadPackages,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              children: [
                ...staggered([
                  Bleed(
                    amount: 4,
                    child: FeedingStepProgress(
                      step: 1,
                      label: 'Food Packages'.tr,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select food Package :'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FeedingLayoutToggle(
                        grid: controller.gridView,
                        onChanged: controller.toggleLayout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SearchPill(hint: 'Search..'.tr, onChanged: controller.search),
                ]),
                const SizedBox(height: 14),
                if (controller.gridView)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 600 ? 3 : 2;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 12) / columns;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final item in state.visiblePackages)
                            SizedBox(
                              width: width,
                              child: _PackageCard(
                                item: item,
                                quantity: state.quantityFor(item.id),
                                grid: true,
                                onChanged: (value) =>
                                    controller.setQuantity(item, value),
                              ),
                            ),
                        ],
                      );
                    },
                  )
                else
                  for (final (index, item)
                      in state.visiblePackages.indexed) ...[
                    _entrance(
                      key: ValueKey(item.id),
                      index: index,
                      child: _PackageCard(
                        item: item,
                        quantity: state.quantityFor(item.id),
                        onChanged: (value) =>
                            controller.setQuantity(item, value),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      onPressed: state.lines.isEmpty
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

/// Quantities are a local draft until the backend supports a basket contract.
class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.item,
    required this.quantity,
    required this.onChanged,
    this.grid = false,
  });
  final CharityPackage item;
  final bool grid;
  final int quantity;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final photo = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: grid ? 1.35 : 1,
        child: LocalOrNetworkImage(item.imageUrl ?? item.image),
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          maxLines: grid ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          item.impact.isEmpty ? item.food : item.impact,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: AppTheme.secondaryFontFamily,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.priceLabel,
          style: const TextStyle(
            fontSize: 18,
            color: AppColors.brand,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final selection = FeedingQuantityControl(
      quantity: quantity,
      name: item.name,
      onChanged: onChanged,
      horizontal: grid,
    );
    return Semantics(
      selected: quantity > 0,
      button: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder, width: 1),
        ),
        child: SurfaceCard(
          radius: 12,
          onTap: quantity == 0 ? () => onChanged(1) : null,
          padding: const EdgeInsets.all(12),
          child: grid
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    photo,
                    const SizedBox(height: 10),
                    copy,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: selection,
                    ),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 90, child: photo),
                    const SizedBox(width: 12),
                    Expanded(child: copy),
                    const SizedBox(width: 8),
                    selection,
                  ],
                ),
        ),
      ),
    );
  }
}
