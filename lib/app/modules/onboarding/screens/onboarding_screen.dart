import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/zoovana_ui.dart';

/// How a page's photo settles into its frame when the page becomes active.
enum _PhotoMotion {
  /// Pulls back from the bottom of the frame, like a camera rising.
  rise,

  /// Glides sideways across a wide landscape.
  pan,

  /// Slowly zooms out from a close-up of [_OnboardingPageData.focus].
  embrace,
}

/// How a page's title and body arrive in the panel.
enum _CopyMotion { rise, slide, pop }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  /// 1 when the last page change moved forward, -1 when it moved back.
  int _direction = 1;
  Drag? _panelDrag;

  static const _pages = [
    _OnboardingPageData(
      asset: AppAssets.feedingMakkah,
      title: 'Feed Cats & Birds in Makkah',
      body:
          'Choose a food package for cats and birds in Makkah. A local operator arranges the feeding.',
      photoMotion: _PhotoMotion.rise,
      copyMotion: _CopyMotion.rise,
    ),
    _OnboardingPageData(
      asset: AppAssets.feedingMadinah,
      title: 'Support Feeding in Madinah',
      body:
          'Help feed cats and birds in Madinah. Local operators buy the food and carry out your request.',
      photoMotion: _PhotoMotion.pan,
      copyMotion: _CopyMotion.slide,
    ),
    _OnboardingPageData(
      asset: AppAssets.feedingBirds,
      title: 'See Your Feeding Impact',
      body:
          'Follow your cats and birds feeding request in Makkah or Madinah, with photos after approval.',
      photoMotion: _PhotoMotion.embrace,
      copyMotion: _CopyMotion.pop,
      focus: Alignment(-.1, -.15),
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    await Get.find<SharedPreferences>().setBool(
      'zoovana_onboarding_complete_v1',
      true,
    );
    Get.offAllNamed(AppRoutes.auth);
  }

  void _continue() {
    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: AppMotion.slow,
      curve: AppMotion.emphasized,
    );
  }

  void _onPageChanged(int value) {
    HapticFeedback.selectionClick();
    setState(() {
      _direction = value > _index ? 1 : -1;
      _index = value;
    });
  }

  // Only the photo sits in the PageView, so drags on the panel are handed to
  // its scroll position to keep the whole screen swipeable.
  void _panelDragStart(DragStartDetails details) => _panelDrag = _pageController
      .position
      .drag(details, () => _panelDrag = null);

  void _panelDragUpdate(DragUpdateDetails details) =>
      _panelDrag?.update(details);

  void _panelDragEnd(DragEndDetails details) => _panelDrag?.end(details);

  void _panelDragCancel() => _panelDrag?.cancel();

  @override
  void dispose() {
    _panelDrag?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Column(
          children: [
            Expanded(
              // The photos run under the panel's rounded corners.
              child: ClipRect(
                clipper: const _BleedBelow(_photoBleed),
                child: PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: _pages.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => AppPageMotion(
                    controller: _pageController,
                    pageIndex: index,
                    horizontalOffset: 54,
                    inactiveOpacity: 0.72,
                    inactiveScale: 1.05,
                    child: Stack(
                      fit: StackFit.expand,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          bottom: -_photoBleed,
                          child: _OnboardingPhoto(
                            data: _pages[index],
                            active: index == _index,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragStart: _panelDragStart,
              onHorizontalDragUpdate: _panelDragUpdate,
              onHorizontalDragEnd: _panelDragEnd,
              onHorizontalDragCancel: _panelDragCancel,
              child: AppEntranceAnimation(
                duration: AppMotion.slow,
                beginOffset: const Offset(0, .35),
                child: _OnboardingPanel(
                  pages: _pages,
                  index: _index,
                  direction: _direction,
                  continueLabel: (_isLast ? 'Start now' : 'Continue').tr,
                  onContinue: _continue,
                  onSkip: _finish,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _photoBleed = 70.0;

/// Clips to the child's bounds but lets it paint [amount] points below them.
class _BleedBelow extends CustomClipper<Rect> {
  const _BleedBelow(this.amount);

  final double amount;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height + amount);

  @override
  bool shouldReclip(covariant _BleedBelow oldClipper) =>
      oldClipper.amount != amount;
}

/// Page photo that settles into its designed framing the first time its page
/// becomes active. Until then it holds the opening pose, so a page dragged
/// into view is already set up for its move.
class _OnboardingPhoto extends StatefulWidget {
  const _OnboardingPhoto({required this.data, required this.active});

  final _OnboardingPageData data;
  final bool active;

  @override
  State<_OnboardingPhoto> createState() => _OnboardingPhotoState();
}

class _OnboardingPhotoState extends State<_OnboardingPhoto>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: switch (widget.data.photoMotion) {
      _PhotoMotion.rise => const Duration(milliseconds: 2400),
      _PhotoMotion.pan => const Duration(milliseconds: 3000),
      _PhotoMotion.embrace => const Duration(milliseconds: 2800),
    },
  );
  late final _progress = CurvedAnimation(
    parent: _controller,
    curve: widget.data.photoMotion == _PhotoMotion.pan
        ? Curves.easeInOutSine
        : Curves.easeOutQuart,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _settleIfActive();
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _settleIfActive();
  }

  void _settleIfActive() {
    if (widget.active && _controller.isDismissed) _controller.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final t = _progress.value;
        if (t >= 1) return Image.asset(data.asset, fit: BoxFit.cover);
        return switch (data.photoMotion) {
          _PhotoMotion.rise => Transform.scale(
            scale: 1 + .14 * (1 - t),
            alignment: Alignment.bottomCenter,
            child: Image.asset(data.asset, fit: BoxFit.cover),
          ),
          _PhotoMotion.pan => Transform.scale(
            scale: 1 + .06 * (1 - t),
            child: Image.asset(
              data.asset,
              fit: BoxFit.cover,
              alignment: Alignment(-.85 * (1 - t), 0),
            ),
          ),
          _PhotoMotion.embrace => Transform.scale(
            scale: 1 + .2 * (1 - t),
            alignment: data.focus,
            child: Image.asset(data.asset, fit: BoxFit.cover),
          ),
        };
      },
    );
  }
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({
    required this.pages,
    required this.index,
    required this.direction,
    required this.continueLabel,
    required this.onContinue,
    required this.onSkip,
  });

  final List<_OnboardingPageData> pages;
  final int index;
  final int direction;
  final String continueLabel;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  /// [sign] is -1 right to left, where the pages run the other way.
  Widget _transition(Widget child, Animation<double> animation, int sign) {
    final page = (child.key! as ValueKey<int>).value;
    final incoming = page == index;
    final fade = FadeTransition(opacity: animation, child: child);
    return switch (pages[page].copyMotion) {
      _CopyMotion.rise => SlideTransition(
        position: Tween(
          begin: const Offset(0, .18),
          end: Offset.zero,
        ).animate(animation),
        child: fade,
      ),
      // Follows the swipe: in from the side being paged towards, out the
      // other side.
      _CopyMotion.slide => SlideTransition(
        position: Tween(
          begin: Offset(.22 * sign * (incoming ? direction : -direction), 0),
          end: Offset.zero,
        ).animate(animation),
        child: fade,
      ),
      _CopyMotion.pop => ScaleTransition(
        scale: Tween<double>(
          begin: .88,
          end: 1,
        ).animate(CurvedAnimation(parent: animation, curve: AppMotion.spring)),
        child: fade,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final data = pages[index];
    final sign = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    // The panel sizes to its content so larger text never overflows it.
    final panel = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 66, 20, math.max(33, bottomPadding)),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(56)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var dot = 0; dot < pages.length; dot++)
                _PageDot(reached: dot <= index, current: dot == index),
            ],
          ),
          const SizedBox(height: 44),
          // Titles wrap to different heights, so the panel eases between them.
          AnimatedSize(
            duration: AppMotion.slow,
            curve: AppMotion.emphasized,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: AppMotion.slow,
              reverseDuration: AppMotion.medium,
              switchInCurve: AppMotion.curve,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) =>
                  _transition(child, animation, sign),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: _PageCopy(key: ValueKey(index), data: data),
            ),
          ),
          const SizedBox(height: 22),
          PillButton(
            label: continueLabel,
            fontWeight: FontWeight.w500,
            onPressed: onContinue,
          ),
          const SizedBox(height: 16),
          PillButton(
            label: 'Skip'.tr,
            style: PillButtonStyle.white,
            fontWeight: FontWeight.w500,
            onPressed: onSkip,
          ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        panel,
        Positioned(
          top: -36,
          child: _LogoBadge(page: index, celebrate: index == pages.length - 1),
        ),
      ],
    );
  }
}

class _PageCopy extends StatelessWidget {
  const _PageCopy({super.key, required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        data.title.tr,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 11),
      Text(
        data.body.tr,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF8E8E8E),
          fontSize: 13.5,
          height: 1.35,
        ),
      ),
    ],
  );
}

/// Progress dot that fills with the accent colour and gives a small bump as
/// it becomes the current page.
class _PageDot extends StatelessWidget {
  const _PageDot({required this.reached, required this.current});

  final bool reached;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final dot = AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.curve,
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: reached ? AppColors.accent : Colors.white,
        shape: BoxShape.circle,
      ),
    );
    if (!current || MediaQuery.disableAnimationsOf(context)) return dot;
    // Swapping in the builder starts a fresh bump on every page change.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slow,
      curve: AppMotion.curve,
      child: dot,
      builder: (context, t, child) => t >= 1
          ? child!
          : Transform.scale(
              scale: 1 + .6 * math.sin(math.pi * t),
              child: child,
            ),
    );
  }
}

/// Logo in its accent ring. It wobbles on each page change and beats like a
/// heart on the last page.
class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.page, required this.celebrate});

  final int page;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent),
      ),
      child: Image.asset(
        AppAssets.logo,
        fit: BoxFit.contain,
        semanticLabel: 'Zoovana logo'.tr,
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return badge;
    return TweenAnimationBuilder<double>(
      key: ValueKey(page),
      tween: Tween(begin: 0, end: 1),
      duration: celebrate
          ? const Duration(milliseconds: 1100)
          : const Duration(milliseconds: 700),
      child: badge,
      builder: (context, t, child) {
        if (t >= 1) return child!;
        final fade = 1 - t;
        if (celebrate) {
          // Two beats, the second softer.
          final beat = math.sin(2 * math.pi * t).abs() * fade;
          return Transform.scale(scale: 1 + .16 * beat, child: child);
        }
        return Transform.rotate(
          angle: .22 * math.sin(3 * math.pi * t) * fade,
          child: Transform.scale(
            scale: 1 + .08 * math.sin(math.pi * t),
            child: child,
          ),
        );
      },
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.asset,
    required this.title,
    required this.body,
    required this.photoMotion,
    required this.copyMotion,
    this.focus = Alignment.center,
  });

  final String asset;
  final String title;
  final String body;
  final _PhotoMotion photoMotion;
  final _CopyMotion copyMotion;

  /// Where an [_PhotoMotion.embrace] zoom is centred.
  final Alignment focus;
}
