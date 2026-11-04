import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Adds subtle, gesture-driven motion to a child inside a [PageView].
///
/// The child is fully visible on its page and transitions continuously as the
/// user drags. This avoids delayed or replayed animations fighting the page
/// gesture. Values greater than `1` for [inactiveScale] create a gentle
/// zoom-out effect; values below `1` create a zoom-in effect.
class AppPageMotion extends StatelessWidget {
  const AppPageMotion({
    super.key,
    required this.controller,
    required this.pageIndex,
    required this.child,
    this.horizontalOffset = 28,
    this.inactiveOpacity = 0.55,
    this.inactiveScale = 0.98,
  }) : assert(inactiveOpacity >= 0 && inactiveOpacity <= 1),
       assert(inactiveScale > 0);

  final PageController controller;
  final int pageIndex;
  final Widget child;
  final double horizontalOffset;
  final double inactiveOpacity;
  final double inactiveScale;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }

    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        var currentPage = controller.initialPage.toDouble();
        if (controller.hasClients && controller.position.hasContentDimensions) {
          currentPage = controller.page ?? currentPage;
        }

        final pageDelta = pageIndex - currentPage;
        final distance = pageDelta.abs().clamp(0.0, 1.0);
        final opacity = 1 - ((1 - inactiveOpacity) * distance);
        final scale = 1 - ((1 - inactiveScale) * distance);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(-pageDelta * horizontalOffset, 0),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

/// A reusable entrance animation that can fade, slide, and scale any widget.
///
/// Set [trigger] to `false` to leave the child in its resting state. Changing
/// it from `false` to `true` replays the animation, which is useful for pages,
/// tabs, and list items that can become active more than once.
///
/// The [delay] is part of the animation's timeline rather than a timer, so
/// the child always settles once frames stop being scheduled.
class AppEntranceAnimation extends StatefulWidget {
  const AppEntranceAnimation({
    super.key,
    required this.child,
    this.trigger = true,
    this.duration = AppMotion.medium,
    this.delay = Duration.zero,
    this.curve = AppMotion.curve,
    this.beginOffset = const Offset(0, 0.08),
    this.beginScale = 1,
  });

  const AppEntranceAnimation.fade({
    super.key,
    required this.child,
    this.trigger = true,
    this.duration = AppMotion.medium,
    this.delay = Duration.zero,
    this.curve = AppMotion.curve,
  }) : beginOffset = Offset.zero,
       beginScale = 1;

  const AppEntranceAnimation.pop({
    super.key,
    required this.child,
    this.trigger = true,
    this.duration = AppMotion.medium,
    this.delay = Duration.zero,
    this.curve = AppMotion.spring,
    this.beginScale = 0.88,
  }) : beginOffset = Offset.zero;

  final Widget child;
  final bool trigger;
  final Duration duration;
  final Duration delay;

  /// Drives the slide and scale. Opacity always eases out without overshoot,
  /// so springy curves are safe here.
  final Curve curve;
  final Offset beginOffset;
  final double beginScale;

  @override
  State<AppEntranceAnimation> createState() => _AppEntranceAnimationState();
}

class _AppEntranceAnimationState extends State<AppEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _slide;

  bool _dependenciesReady = false;
  bool _reduceMotion = false;

  Duration get _total => widget.delay + widget.duration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _total,
      value: widget.trigger ? 0 : 1,
    );
    _configureAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final firstRun = !_dependenciesReady;
    final changed = reduceMotion != _reduceMotion;
    _dependenciesReady = true;
    _reduceMotion = reduceMotion;

    if (_reduceMotion) {
      _controller.value = 1;
    } else if (firstRun || changed) {
      _playIfTriggered();
    }
  }

  @override
  void didUpdateWidget(covariant AppEntranceAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration ||
        oldWidget.delay != widget.delay) {
      _controller.duration = _total;
    }
    if (oldWidget.duration != widget.duration ||
        oldWidget.delay != widget.delay ||
        oldWidget.curve != widget.curve ||
        oldWidget.beginOffset != widget.beginOffset ||
        oldWidget.beginScale != widget.beginScale) {
      _configureAnimations();
    }

    if (!widget.trigger) {
      _controller.value = 1;
    } else if (!oldWidget.trigger) {
      _playIfTriggered();
    }
  }

  void _configureAnimations() {
    // Seconds over seconds, exactly as the controller computes its value, so
    // the child is fully hidden for the whole delay.
    double seconds(Duration d) =>
        d.inMicroseconds / Duration.microsecondsPerSecond;
    final total = seconds(_total);
    final start = total == 0 ? 0.0 : seconds(widget.delay) / total;
    final motion = CurveTween(curve: Interval(start, 1, curve: widget.curve));
    _opacity = _controller
        .drive(CurveTween(curve: Interval(start, 1, curve: Curves.easeOut)))
        .drive(Tween<double>(begin: 0, end: 1));
    _scale = _controller
        .drive(motion)
        .drive(Tween<double>(begin: widget.beginScale, end: 1));
    _slide = _controller
        .drive(motion)
        .drive(Tween<Offset>(begin: widget.beginOffset, end: Offset.zero));
  }

  void _playIfTriggered() {
    if (!widget.trigger || _reduceMotion) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

/// Wraps [children] in [AppEntranceAnimation]s with increasing delays so a
/// screen's sections cascade in.
///
/// Spacers, and widgets such as [Expanded] or [Positioned] that must stay
/// direct children of their parent, pass through without using a step.
/// Only the first
/// [maxSteps] items animate: lazily built lists create later items while the
/// user scrolls, and those should simply be there.
List<Widget> staggered(
  Iterable<Widget> children, {
  bool trigger = true,
  Duration initialDelay = Duration.zero,
  Duration interval = AppMotion.stagger,
  Duration duration = AppMotion.slow,
  Offset beginOffset = const Offset(0, 0.06),
  int maxSteps = 8,
}) {
  var step = 0;
  return [
    for (final child in children)
      if (child is ParentDataWidget ||
          child is Spacer ||
          (child is SizedBox && child.child == null) ||
          step >= maxSteps)
        child
      else
        AppEntranceAnimation(
          trigger: trigger,
          duration: duration,
          delay: initialDelay + interval * step++,
          beginOffset: beginOffset,
          child: child,
        ),
  ];
}

/// [AnimatedSwitcher.layoutBuilder] that keeps the outgoing and incoming
/// children at the parent's constraints and pins them to the top, so switched
/// content rests exactly where it would without the switcher.
Widget pinnedSwitcherLayout(Widget? current, List<Widget> previous) => Stack(
  alignment: Alignment.topCenter,
  fit: StackFit.passthrough,
  children: [...previous, ?current],
);

/// Shrinks [child] slightly while a pointer is down on it, as tactile
/// feedback for buttons and tappable cards. Gestures are still handled by the
/// child; the press is released once the pointer moves far enough to scroll.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;
  Offset? _origin;

  void _press(PointerDownEvent event) {
    _origin = event.position;
    setState(() => _pressed = true);
  }

  void _move(PointerMoveEvent event) {
    final origin = _origin;
    if (!_pressed || origin == null) return;
    if ((event.position - origin).distance > kTouchSlop) _release();
  }

  void _release([PointerEvent? _]) {
    _origin = null;
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.enabled || reduceMotion) return widget.child;
    return Listener(
      onPointerDown: _press,
      onPointerMove: _move,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Cross-fades and slides between values of a short label, such as a count
/// or a button title. The text slides up when [value] grows and down when it
/// shrinks, so steppers feel directional.
class AppAnimatedLabel extends StatefulWidget {
  const AppAnimatedLabel(
    this.text, {
    super.key,
    this.value,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;

  /// Optional ordering for [text]; defaults to sliding up.
  final num? value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<AppAnimatedLabel> createState() => _AppAnimatedLabelState();
}

class _AppAnimatedLabelState extends State<AppAnimatedLabel> {
  double _direction = 1;

  @override
  void didUpdateWidget(covariant AppAnimatedLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.value;
    final next = widget.value;
    if (previous != null && next != null && previous != next) {
      _direction = next > previous ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(widget.text);
        final travel = incoming ? _direction : -_direction;
        return ClipRect(
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, .6 * travel),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: Text(
        widget.text,
        key: ValueKey(widget.text),
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}
