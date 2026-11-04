import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/assets/app_assets.dart';
import '../../core/assets/app_icons.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import 'app_animations.dart';

/// Teal surface with the low-contrast contour lines used by Figma headers.
class TealPatternBackground extends StatelessWidget {
  const TealPatternBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: const _ContourPainter(), child: child);
}

class _ContourPainter extends CustomPainter {
  const _ContourPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.brand);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (var row = -size.width * .4; row < size.height + 40; row += 11) {
      final path = Path();
      for (var x = -10.0; x <= size.width + 10; x += 6) {
        final y =
            row +
            x * .32 +
            math.sin(x / 34 + row / 23) * 5 +
            math.sin(x / 11 + row / 7) * 1.4;
        x <= -10 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pale page background with the repeating animal pattern.
class AnimalPatternBackground extends StatelessWidget {
  const AnimalPatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: Color(0xFFF9FAFA)),
      Image.asset(
        AppAssets.splashBackground,
        alignment: Alignment.topCenter,
        fit: BoxFit.none,
        repeat: ImageRepeat.repeat,
      ),
      child,
    ],
  );
}

/// Logo mark followed by the ZOOVANA word mark.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.light = true});

  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        light ? AppAssets.logoLight : AppAssets.logo,
        width: 24,
        height: 32,
        semanticLabel: 'Zoovana logo'.tr,
      ),
      const SizedBox(width: 4),
      Text(
        'ZOOVANA',
        style: TextStyle(
          color: light ? Colors.white : AppColors.textPrimary,
          fontSize: 30,
          height: 1,
          fontWeight: FontWeight.w400,
          letterSpacing: -.2,
        ),
      ),
    ],
  );
}

/// Round translucent header action with a white outline.
class HeaderCircleButton extends StatelessWidget {
  const HeaderCircleButton({
    super.key,
    this.icon,
    this.iconWidget,
    required this.onTap,
    this.tooltip,
    this.badge = false,
  });

  final IconData? icon;

  /// Custom glyph used instead of [icon].
  final Widget? iconWidget;
  final VoidCallback onTap;
  final String? tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    child: AppPressable(
      pressedScale: .9,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .15),
            border: Border.all(
              color: Colors.white.withValues(alpha: .6),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              iconWidget ?? Icon(icon, color: Colors.white, size: 22),
              if (badge)
                PositionedDirectional(
                  top: 9,
                  end: 10,
                  child: AppEntranceAnimation.pop(
                    delay: AppMotion.slow,
                    beginScale: 0,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Teal brand header used on the customer and provider tabs.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.actions,
    this.child,
    this.bottomPadding = 24,
  });

  final List<Widget> actions;
  final Widget? child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: TealPatternBackground(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            math.max(12, top - 2),
            20,
            bottomPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const BrandWordmark(),
                  const Spacer(),
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
              ?child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Greeting and location lines shown beneath the brand header row.
class HeaderGreeting extends StatelessWidget {
  const HeaderGreeting({
    super.key,
    required this.greeting,
    required this.location,
    this.locationSize = 16,
  });

  final double locationSize;

  final String greeting;
  final String location;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              greeting,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 9),
            const AssetIcon(AppIcons.waveHand, size: 21),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Iconsax.location_copy,
              color: Colors.white.withValues(alpha: .85),
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .85),
                  fontSize: locationSize,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Section title with the teal "View all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.uppercase = false,
    this.titleSize = 20,
    this.actionSize = 13,
  });

  final String title;

  /// Defaults to "View all".
  final String? action;
  final VoidCallback? onAction;
  final bool uppercase;
  final double titleSize;
  final double actionSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          uppercase ? title.toUpperCase() : title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            letterSpacing: uppercase ? .2 : 0,
          ),
        ),
      ),
      if (onAction != null)
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              action ?? 'View all'.tr,
              style: TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w600,
                fontSize: actionSize,
              ),
            ),
          ),
        ),
    ],
  );
}

enum PillButtonStyle { primary, muted, white }

/// Fully rounded 48 px action button.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillButtonStyle.primary,
    this.isLoading = false,
    this.height = AppSpacing.buttonHeight,
    this.icon,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.shadow = false,
  });

  /// Defaults to 16, or 14 for buttons shorter than 44.
  final double? fontSize;
  final String? fontFamily;
  final FontWeight? fontWeight;

  /// Soft glow under primary buttons inside cards.
  final bool shadow;

  final String label;
  final VoidCallback? onPressed;
  final PillButtonStyle style;
  final bool isLoading;
  final double height;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (style) {
      PillButtonStyle.primary => (AppColors.brand, Colors.white),
      PillButtonStyle.muted => (AppColors.surfaceMuted, AppColors.textPrimary),
      PillButtonStyle.white => (Colors.white, AppColors.textPrimary),
    };
    final button = Container(
      height: height,
      width: double.infinity,
      decoration: shadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            )
          : null,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: .6),
          disabledForegroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
          textStyle: AppTheme.buttonTextStyle.copyWith(
            fontSize: fontSize ?? (height < 44 ? 14 : 16),
            fontFamily: fontFamily,
            fontWeight: fontWeight,
          ),
        ),
        // Labels and the loading spinner cross-fade, e.g. "Continue" to
        // "Start now" or a submit turning into progress.
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          switchInCurve: AppMotion.curve,
          switchOutCurve: AppMotion.curve,
          child: isLoading
              ? SizedBox.square(
                  key: const ValueKey('loading'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              : Row(
                  key: ValueKey(label),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      if (label.isNotEmpty) const SizedBox(width: 8),
                    ],
                    if (label.isNotEmpty)
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
    return AppPressable(
      enabled: onPressed != null && !isLoading,
      child: button,
    );
  }
}

/// Space under a bottom bar's content. Clears the gesture handle, the
/// three-button navigation bar or the iPhone home indicator, and keeps a
/// small margin on phones without any. The inset is 0 while the keyboard is
/// open, so the bar then sits just above the keyboard.
double systemNavGap(BuildContext context, {double min = 16}) =>
    math.max(min, MediaQuery.paddingOf(context).bottom + 6);

/// White footer that holds the screen's primary actions.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children, this.flexes});

  final List<Widget> children;

  /// Relative widths of [children]; equal when omitted.
  final List<int>? flexes;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 16,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.only(bottom: systemNavGap(context)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(flex: flexes?[i] ?? 1, child: children[i]),
            ],
          ],
        ),
      ),
    ),
  );
}

/// "STEP 1 OF 3 • Label" heading with segmented progress.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.step,
    required this.total,
    required this.label,
  });

  final int step;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(
            'STEP @step OF @total'.trParams({
              'step': '$step',
              'total': '$total',
            }),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
          const Spacer(),
          const Icon(Icons.circle, size: 5, color: AppColors.brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: AnimatedContainer(
                duration: AppMotion.medium,
                curve: AppMotion.curve,
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

/// White pill search field with search and filter icons.
class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    this.onChanged,
    this.hint,
    this.readOnly = false,
    this.fill = Colors.white,
  });

  final ValueChanged<String>? onChanged;

  /// Defaults to "Search..".
  final String? hint;
  final bool readOnly;
  final Color fill;

  static const _textStyle = TextStyle(
    fontFamily: AppTheme.secondaryFontFamily,
    fontSize: 13,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
      borderSide: BorderSide(color: AppColors.fieldBorder),
    );
    return SizedBox(
      height: 37,
      child: TextField(
        onChanged: onChanged,
        readOnly: readOnly,
        style: _textStyle,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint ?? 'Search..'.tr,
          hintStyle: _textStyle,
          filled: true,
          fillColor: fill,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          prefixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(start: 9, end: 8),
            child: Icon(Icons.search_rounded, color: AppColors.brand, size: 19),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 37,
            minHeight: 37,
          ),
          suffixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(end: 14),
            child: Icon(
              Iconsax.setting_5_copy,
              color: AppColors.brand,
              size: 15,
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 37,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.brand),
          ),
        ),
      ),
    );
  }
}

/// Horizontal pill tabs: coral when selected, white otherwise.
class FilterPills extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.expand = false,
    this.height = 31,
  });

  final double height;

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final bool expand;

  Widget _pill(int index) {
    final active = index == selected;
    return AppPressable(
      pressedScale: .94,
      child: GestureDetector(
        onTap: () => onSelected(index),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: active ? AppColors.accent : const Color(0xFFE4E4E4),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.medium,
              curve: AppMotion.curve,
              // Replaces the inherited style, so the app font is set here.
              style: TextStyle(
                fontFamily: AppTheme.primaryFontFamily,
                fontFamilyFallback: AppTheme.fallbackFontFamilies,
                color: active ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
              child: Text(labels[index], maxLines: 1),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (expand) {
      return Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _pill(i)),
          ],
        ],
      );
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => _pill(index),
      ),
    );
  }
}

/// Small rounded status label, e.g. "Completed" or "Accept in 02:23".
class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    constraints: const BoxConstraints(minWidth: 94),
    padding: const EdgeInsets.symmetric(horizontal: 11),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

/// White rounded card with the light outline used across the frames.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = AppRadius.medium,
    this.onTap,
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 20,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: const BorderSide(color: AppColors.fieldBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return AppPressable(enabled: onTap != null, pressedScale: .98, child: card);
  }
}

/// Icon + text row in grey, e.g. donor name or location lines.
class IconLine extends StatelessWidget {
  const IconLine({
    super.key,
    required this.icon,
    required this.text,
    this.size = 14,
    this.color = AppColors.textPrimary,
    this.iconSize,
  });

  final IconData icon;
  final String text;
  final double size;
  final Color color;

  /// Defaults to slightly larger than the text.
  final double? iconSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: iconSize ?? size + 6, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: size, color: color),
        ),
      ),
    ],
  );
}

/// Teal minus/plus quantity control; collapses to a single plus at zero.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.count,
    required this.onChanged,
  });

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, int next) => InkResponse(
      onTap: () => onChanged(next),
      radius: 16,
      child: SizedBox.square(
        dimension: 26,
        child: Icon(icon, size: 16, color: AppColors.brand),
      ),
    );
    return Container(
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      // Grows from the lone plus into the full stepper.
      child: AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        child: count == 0
            ? Semantics(label: 'Add'.tr, child: button(Icons.add_rounded, 1))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button(Icons.remove_rounded, count - 1),
                  SizedBox(
                    width: 34,
                    child: AppAnimatedLabel(
                      '$count',
                      value: count,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  button(Icons.add_rounded, count + 1),
                ],
              ),
      ),
    );
  }
}

/// Full-screen confirmation used after donations and provider jobs.
class SuccessView extends StatelessWidget {
  const SuccessView({
    super.key,
    required this.title,
    this.actions = const [],
    this.onTap,
    this.message,
  });

  final String title;

  /// Defaults to the order-preparing note.
  final String? message;
  final List<Widget> actions;

  /// Tapping anywhere continues, for confirmations that have no buttons.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        extendBody: true,
        body: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppAssets.successConfetti),
                alignment: Alignment.topCenter,
                fit: BoxFit.fitWidth,
                repeat: ImageRepeat.repeatY,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _SuccessCheck(),
                    const SizedBox(height: 14),
                    // The copy follows once the tick has been drawn.
                    ...staggered(
                      initialDelay: _SuccessCheck.duration * .55,
                      interval: AppMotion.stagger * 2,
                      beginOffset: const Offset(0, .25),
                      [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message ??
                              "We're preparing your order now and will let you know when it's ready. Thank you!"
                                  .tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15.5, height: 1.15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: actions.isEmpty
            ? null
            : DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    systemNavGap(context),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: staggered(
                      initialDelay: _SuccessCheck.duration * .75,
                      beginOffset: const Offset(0, .4),
                      [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          actions[i],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// The brand check, drawn on: the ring sweeps round and the tick follows it
/// out of the gap, with a slight pop as the stroke lands.
class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();

  static const duration = Duration(milliseconds: 900);

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: _SuccessCheck.duration,
  );
  late final _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, .6, curve: Curves.easeInOutCubic),
  );
  late final _tick = CurvedAnimation(
    parent: _controller,
    curve: const Interval(.55, .9, curve: Curves.easeOutCubic),
  );
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: .7, end: 1), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.08), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 20),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    _tick.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: CustomPaint(
      size: const Size.square(82),
      painter: _CheckPainter(ring: _ring, tick: _tick),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.ring, required this.tick})
    : super(repaint: Listenable.merge([ring, tick]));

  final Animation<double> ring;
  final Animation<double> tick;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .085;
    final paint = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final radius = (size.width - stroke) / 2;
    final center = size.center(Offset.zero);
    // The ring opens at the upper right where the tick leaves it.
    const tail = -math.pi * .2;
    const sweep = math.pi * 1.78;
    // The ring is drawn backwards from the gap so it finishes where the tick
    // starts.
    if (ring.value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        tail + sweep * (1 - ring.value),
        sweep * ring.value,
        false,
        paint,
      );
    }
    if (tick.value <= 0) return;
    final check = Path()
      ..moveTo(size.width * .3, size.height * .5)
      ..lineTo(size.width * .46, size.height * .64)
      ..lineTo(
        center.dx + radius * math.cos(tail - .12),
        center.dy + radius * math.sin(tail - .12),
      );
    if (tick.value >= 1) {
      canvas.drawPath(check, paint);
      return;
    }
    final metric = check.computeMetrics().single;
    canvas.drawPath(metric.extractPath(0, metric.length * tick.value), paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.ring != ring || oldDelegate.tick != tick;
}

/// Outlined pill field whose label sits on the border, as in the auth and
/// payment frames.
InputDecoration pillFieldDecoration({
  required String label,
  IconData? icon,
  Widget? suffix,
  String? hint,
  String? errorText,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  errorText: errorText,
  prefixIcon: icon == null
      ? null
      : Padding(
          padding: const EdgeInsetsDirectional.only(start: 18, end: 10),
          child: Icon(icon, size: 22),
        ),
  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
  suffixIcon: suffix,
);

/// Label with a coral required marker, as used above every form field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = true});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text.rich(
      TextSpan(
        text: text,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.accent),
            ),
        ],
      ),
      style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
    ),
  );
}

/// Input and hint text in the frames use Poppins rather than Glory.
const fieldTextStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 13,
  color: AppColors.textPrimary,
);
const _fieldHintStyle = TextStyle(
  fontFamily: 'Poppins',
  color: Color(0xFFA3A3A3),
  fontSize: 13,
);

/// White pill input with no visible outline, from the signup and payment
/// frames.
InputDecoration filledFieldDecoration({
  String? hint,
  IconData? icon,
  Widget? leading,
  Widget? suffix,
  String? errorText,
  bool compact = false,
}) {
  final glyph =
      leading ??
      (icon == null
          ? null
          : Icon(icon, size: 22, color: const Color(0xFF8E8E8E)));
  final vertical = compact ? 11.5 : 14.0;
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
    borderSide: BorderSide(color: AppColors.fieldBorder),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: _fieldHintStyle,
    errorText: errorText,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: EdgeInsetsDirectional.fromSTEB(
      glyph == null ? 16 : 0,
      vertical,
      16,
      vertical,
    ),
    prefixIcon: glyph == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 10),
            child: SizedBox.square(dimension: 22, child: Center(child: glyph)),
          ),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.brand),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.accent),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: AppColors.accent),
    ),
  );
}

/// Label above a white pill text field.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.icon,
    this.suffix,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.required = true,
    this.compact = false,
    this.leading,
  });

  /// Custom glyph used instead of [icon].
  final Widget? leading;

  /// Shorter field, as on the payment form.
  final bool compact;
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final Widget? suffix;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool required;

  /// Phone numbers and emails read left to right in every language; in
  /// Arabic and Urdu they still sit on the right, next to the label.
  bool get _leftToRightValue =>
      keyboardType == TextInputType.phone ||
      keyboardType == TextInputType.emailAddress;

  @override
  Widget build(BuildContext context) {
    final ltrValue = _leftToRightValue;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final decoration = filledFieldDecoration(
      hint: hint,
      icon: icon,
      leading: leading,
      // Skipped by "next", so it goes to the following field, not the
      // show-password button.
      suffix: suffix == null ? null : ExcludeFocus(child: suffix!),
      errorText: errorText,
      compact: compact,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          // The keyboard's action key moves to the next field of the form.
          textInputAction: TextInputAction.next,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: fieldTextStyle,
          textDirection: ltrValue ? TextDirection.ltr : null,
          textAlign: ltrValue && rtl ? TextAlign.end : TextAlign.start,
          decoration: ltrValue
              ? decoration.copyWith(hintTextDirection: TextDirection.ltr)
              : decoration,
        ),
      ],
    );
  }
}

/// Label above a white pill that opens a list of choices.
class LabeledDropdown extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint,
    this.icon,
    this.leading,
  });

  final Widget? leading;

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  /// Defaults to "Select".
  final String? hint;
  final IconData? icon;

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in options)
              ListTile(
                title: Text(option),
                trailing: option == value
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FieldLabel(label),
      Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            height: 47,
            padding: const EdgeInsets.only(left: 16, right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              children: [
                if (leading != null || icon != null) ...[
                  SizedBox.square(
                    dimension: 22,
                    child: Center(
                      child:
                          leading ??
                          Icon(icon, size: 22, color: const Color(0xFF8E8E8E)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    value ?? hint ?? 'Select'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: value == null
                        ? fieldTextStyle
                        : fieldTextStyle.copyWith(
                            color: const Color(0xFF8E8E8E),
                          ),
                  ),
                ),
                const Icon(
                  Iconsax.arrow_down_1_copy,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// Teal header with the centred word mark, used by the profile setup flow.
class LogoHeaderScaffold extends StatelessWidget {
  const LogoHeaderScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
    this.onBack,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        bottomNavigationBar: BottomActionBar(children: actions),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.brand,
              padding: EdgeInsets.only(top: top + 8, bottom: 18),
              alignment: Alignment.center,
              child: const BrandWordmark(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Row(
                    children: [
                      BackArrowButton(onTap: onBack ?? Get.back),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large white circle with a placeholder glyph and a camera badge.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({super.key, required this.child, this.onCamera});

  final Widget child;
  final VoidCallback? onCamera;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: child,
          ),
          PositionedDirectional(
            end: -2,
            bottom: 0,
            child: Semantics(
              button: true,
              label: 'Add photo'.tr,
              child: GestureDetector(
                onTap: onCamera,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEDEDED)),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 24 pt back arrow without Material's 48 pt tap padding, so titles start
/// where the frames put them. The hit area still extends past the glyph.
class BackArrowButton extends StatelessWidget {
  const BackArrowButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back'.tr,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Icon(Icons.arrow_back_rounded, size: 24),
      ),
    ),
  );
}

/// Monochrome icon extracted from the Figma frames, tinted with [color].
class AssetIcon extends StatelessWidget {
  const AssetIcon(
    this.asset, {
    super.key,
    this.size = 22,
    this.color = Colors.white,
  });

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    color: color,
    colorBlendMode: BlendMode.srcIn,
    filterQuality: FilterQuality.medium,
  );
}

/// App bar from the frames: the title sits 5 pt above the bar's centre and
/// the back arrow is inset 32 pt. [light] gives the white variant used on the
/// adoption screens.
class ZoovanaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ZoovanaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.light = false,
    this.showBack,
  });

  final String title;
  final List<Widget>? actions;
  final bool light;

  /// Defaults to showing the arrow when the route can pop.
  final bool? showBack;

  static const _toolbar = 36.0;
  static const _below = 10.0;

  /// Total height below the status bar.
  static const height = _toolbar + _below;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbar + _below);

  @override
  Widget build(BuildContext context) {
    final foreground = light ? AppColors.textPrimary : Colors.white;
    final canPop = showBack ?? ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      toolbarHeight: _toolbar,
      backgroundColor: light ? AppColors.surfaceBase : AppColors.brand,
      foregroundColor: foreground,
      systemOverlayStyle: light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      leadingWidth: canPop ? 56 : 0,
      titleSpacing: canPop ? 17 : 20,
      leading: canPop
          ? Semantics(
              button: true,
              label: 'Back'.tr,
              child: GestureDetector(
                onTap: () => Navigator.maybePop(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 32),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: foreground,
                    size: 24,
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: light ? FontWeight.w400 : FontWeight.w500,
        ),
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(_below),
        child: SizedBox.shrink(),
      ),
    );
  }
}

/// Lets [child] extend [amount] points past both sides of its column, for
/// elements the frames draw wider than the surrounding content.
class Bleed extends StatelessWidget {
  const Bleed({super.key, required this.amount, required this.child});

  final double amount;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => FractionallySizedBox(
      widthFactor: (constraints.maxWidth + amount * 2) / constraints.maxWidth,
      child: child,
    ),
  );
}

/// Pale yellow card with the stacked-pets artwork and a white pill action,
/// used for "About Pets Health" on home and the shelter hub.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.actionLabel,
    required this.onAction,
    this.height = 177,
  });

  final String actionLabel;
  final VoidCallback onAction;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: height),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFFEF8E8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _PromoSwirlPainter()),
        ),
        PositionedDirectional(
          end: 40,
          top: 12,
          bottom: 0,
          child: Image.asset(
            AppAssets.homeAdvice,
            fit: BoxFit.fitHeight,
            alignment: Alignment.bottomCenter,
          ),
        ),
        const PositionedDirectional(
          end: 40,
          top: 14,
          child: CustomPaint(size: Size(96, 34), painter: _DoodlePainter()),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 17, 0, 16),
          child: SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Pets Health'.tr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order your free paw collar today to track the movements of your pet'
                      .tr,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, height: 1.15),
                ),
                const SizedBox(height: 16),
                AppPressable(
                  pressedScale: .94,
                  child: GestureDetector(
                    onTap: onAction,
                    child: Container(
                      height: 33,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontFamily: AppTheme.secondaryFontFamily,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _PromoSwirlPainter extends CustomPainter {
  const _PromoSwirlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x55FDE9A9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.height * .2;
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * .25,
        -size.height * .7,
        size.width * .62,
        size.height * 1.6,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .1,
        size.height * .45,
        size.width * .9,
        size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The two hand-drawn squiggles beside the artwork.
class _DoodlePainter extends CustomPainter {
  const _DoodlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(7, 3)
        ..quadraticBezierTo(0, 6, 4, 11)
        ..quadraticBezierTo(10, 13, 5, 19)
        ..quadraticBezierTo(3, 22, 9, 21),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 12, 13)
        ..quadraticBezierTo(size.width - 2, 15, size.width - 6, 21)
        ..quadraticBezierTo(size.width - 10, 27, size.width - 16, 26),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Compact icon, value and label tile. It expands, so place it in a [Row].
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: tint),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Round avatar with the first letters of [name] on the brand tint.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.radius = 28});

  final String name;
  final double radius;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p.characters.first).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.brandSoft,
    child: Text(
      _initials,
      style: TextStyle(
        color: AppColors.brand,
        fontSize: radius * .62,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
