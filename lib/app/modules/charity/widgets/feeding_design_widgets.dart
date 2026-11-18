import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/media_picker.dart';

class FeedingSectionCard extends StatelessWidget {
  const FeedingSectionCard({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFEDEDE8)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Text(
            title.tr,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEDEDE8)),
        child,
      ],
    ),
  );
}

class FeedingInfoRow extends StatelessWidget {
  const FeedingInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.divider = false,
  });
  final String label, value;
  final bool highlight, divider;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: divider
          ? const Border(bottom: BorderSide(color: Color(0xFFEDEDE8)))
          : null,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label.tr,
            style: TextStyle(
              fontSize: 15,
              color: highlight ? AppColors.brand : const Color(0xFF8E8E93),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not available'.tr : value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 15,
              color: highlight ? AppColors.brand : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class FeedingItemRow extends StatelessWidget {
  const FeedingItemRow({
    super.key,
    required this.name,
    required this.image,
    required this.amount,
    required this.quantity,
    this.description = '',
  });
  final String name, image, amount, description;
  final int? quantity;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 300;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: compact ? 74 : 90,
                child: image.isEmpty
                    ? const ColoredBox(
                        color: AppColors.brandSoft,
                        child: Icon(
                          Icons.rice_bowl_outlined,
                          color: AppColors.brand,
                        ),
                      )
                    : LocalOrNetworkImage(image),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Not available'.tr : name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: compact ? 65 : 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount.isEmpty ? '—' : amount,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Qty: @count'.trParams({
                      'count': quantity?.toString() ?? '—',
                    }),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class FeedingQuantityControl extends StatelessWidget {
  const FeedingQuantityControl({
    super.key,
    required this.quantity,
    required this.onChanged,
    required this.name,
    this.horizontal = false,
    this.maxQuantity,
  });
  final int quantity;
  final ValueChanged<int> onChanged;
  final String name;
  final bool horizontal;
  final int? maxQuantity;
  Widget _button(bool add) => SizedBox(
    width: 32,
    height: 32,
    child: IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: '${add ? 'Add'.tr : 'Remove'.tr} $name',
      onPressed: add && maxQuantity != null && quantity >= maxQuantity!
          ? null
          : () => onChanged(quantity + (add ? 1 : -1)),
      icon: Icon(
        add ? Icons.add : Icons.remove,
        size: 24,
        color: AppColors.brand,
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBase,
          shape: BoxShape.circle,
        ),
        child: _button(true),
      );
    }
    final count = Semantics(
      liveRegion: true,
      child: Text(
        '$quantity',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.circular(16),
      ),
      child: horizontal
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [_button(false), count, _button(true)],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [_button(true), count, _button(false)],
            ),
    );
  }
}

class FeedingLayoutToggle extends StatelessWidget {
  const FeedingLayoutToggle({
    super.key,
    required this.grid,
    required this.onChanged,
  });
  final bool grid;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF0EEE7)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final isGrid in [false, true])
          Semantics(
            selected: grid == isGrid,
            button: true,
            label: (isGrid ? 'Grid view' : 'List view').tr,
            child: Tooltip(
              message: (isGrid ? 'Grid view' : 'List view').tr,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onChanged(isGrid),
                child: Container(
                  width: 35,
                  height: 28,
                  decoration: BoxDecoration(
                    color: grid == isGrid
                        ? AppColors.brand
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isGrid ? Icons.grid_view_rounded : Icons.view_list_outlined,
                    size: 19,
                    color: grid == isGrid
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class FeedingStepProgress extends StatelessWidget {
  const FeedingStepProgress({
    super.key,
    required this.step,
    required this.label,
  });
  final int step;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'STEP @step OF @total'.trParams({'step': '$step', 'total': '3'}),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '● $label',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.brand,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i < step ? AppColors.brand : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  );
}
