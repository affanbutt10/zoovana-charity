import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/assets/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import 'app_animations.dart';
import 'zoovana_ui.dart';

class BottomNavDestination {
  const BottomNavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// White rounded navigation bar from the frames. When [onCenterTap] is set a
/// raised coral action is placed in the middle of the destinations.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.onCenterTap,
    this.centerLabel = 'Donate',
    this.centerIcon,
  });

  final List<BottomNavDestination> destinations;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onCenterTap;
  final String centerLabel;
  final IconData? centerIcon;

  /// Width reserved for the raised centre action.
  static const _centerWidth = 61.0;

  /// Height of the icons and labels, above the system navigation inset.
  static const _contentHeight = 60.0;

  /// Bottom padding for a tab's scrolling content, so its end clears the
  /// bar and the raised centre action. Use inside a `Scaffold` with
  /// `extendBody: true`, where the bottom padding is the bar's height.
  static double contentPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 40;

  Widget _item(int index) {
    final destination = destinations[index];
    final selected = index == selectedIndex;
    final color = selected ? AppColors.brand : const Color(0xFFA3A3A3);
    // Labels stay English in the lists and are translated for display.
    final label = destination.label.tr;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onSelected(index),
        radius: 34,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            builder: (context, color, _) => Column(
              children: [
                _NavIcon(
                  icon: destination.icon,
                  color: color,
                  selected: selected,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: TextStyle(color: color, fontSize: 12, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The labels stay above the gesture handle or the system buttons.
    final inset = math.max(MediaQuery.paddingOf(context).bottom, 10.0);
    final hasCenter = onCenterTap != null;
    final half = destinations.length ~/ 2;
    return Container(
      height: _contentHeight + inset,
      padding: EdgeInsets.only(bottom: inset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: hasCenter
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Equal halves keep the centre action centred at any width.
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < half; i++) Expanded(child: _item(i)),
                    ],
                  ),
                ),
                SizedBox(
                  width: _centerWidth,
                  child: OverflowBox(
                    maxHeight: 200,
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -14),
                      child: _CenterAction(
                        label: centerLabel.tr,
                        onTap: onCenterTap!,
                        icon: centerIcon,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = half; i < destinations.length; i++)
                        Expanded(child: _item(i)),
                    ],
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 47),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(child: _item(i)),
                ],
              ),
            ),
    );
  }
}

/// Destination glyph that gives a short bump when it becomes selected.
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.color,
    required this.selected,
  });

  final IconData icon;
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, color: color, size: 25);
    if (!selected || MediaQuery.disableAnimationsOf(context)) return glyph;
    // Swapping in the builder starts a fresh bump on every selection.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.curve,
      child: glyph,
      builder: (context, t, child) => t >= 1
          ? child!
          : Transform.translate(
              offset: Offset(0, -3 * math.sin(math.pi * t)),
              child: Transform.scale(
                scale: 1 + .14 * math.sin(math.pi * t),
                child: child,
              ),
            ),
    );
  }
}

/// Coral siren button sitting in a pale ring above the bar.
class _CenterAction extends StatelessWidget {
  const _CenterAction({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: AppPressable(
      pressedScale: .9,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            shape: BoxShape.circle,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon == null
                  ? const AssetIcon(AppIcons.siren, size: 26)
                  : Icon(icon, size: 32, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}

abstract final class CustomerNav {
  static const destinations = <BottomNavDestination>[
    BottomNavDestination(icon: Iconsax.home_copy, label: 'Home'),
    BottomNavDestination(icon: Iconsax.receipt_2_copy, label: 'Requests'),
    BottomNavDestination(icon: Iconsax.heart_copy, label: 'Impact'),
    // Out of charity scope:
    // BottomNavDestination(icon: Iconsax.pet_copy, label: 'My Pets'),
    // BottomNavDestination(icon: Iconsax.health_copy, label: 'Services'),
    BottomNavDestination(icon: Iconsax.user_copy, label: 'Profile'),
  ];
}

abstract final class ProviderNav {
  static const destinations = <BottomNavDestination>[
    BottomNavDestination(icon: Iconsax.home_copy, label: 'Home'),
    BottomNavDestination(icon: Iconsax.briefcase_copy, label: 'Jobs'),
    BottomNavDestination(icon: Iconsax.user_copy, label: 'Profile'),
  ];
}
