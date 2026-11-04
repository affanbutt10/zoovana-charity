import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _AnimatedSplashContent(),
        GetBuilder<SplashController>(
          builder: (controller) => controller.error == null
              ? const SizedBox.shrink()
              : _SessionRetry(controller: controller),
        ),
      ],
    );
  }
}

/// Shown when the session couldn't be confirmed (e.g. offline or a 503).
/// The login is kept; the user retries instead of signing in again.
class _SessionRetry extends StatelessWidget {
  const _SessionRetry({required this.controller});
  final SplashController controller;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 20,
    right: 20,
    bottom: MediaQuery.paddingOf(context).bottom + 32,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.error!,
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 12),
            controller.isChecking
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : TextButton(
                    onPressed: controller.retry,
                    child: Text('Try again'.tr),
                  ),
          ],
        ),
      ),
    ),
  );
}

class _AnimatedSplashContent extends StatefulWidget {
  const _AnimatedSplashContent();

  @override
  State<_AnimatedSplashContent> createState() => _AnimatedSplashContentState();
}

class _AnimatedSplashContentState extends State<_AnimatedSplashContent>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _ambientController;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  bool _motionPreferenceApplied = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0, .34, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: .78, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0, .48, curve: Curves.easeOutBack),
      ),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, .18), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0, .46, curve: Curves.easeOutCubic),
          ),
        );
    _wordmarkOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(.22, .62, curve: Curves.easeOut),
    );
    _wordmarkSlide =
        Tween<Offset>(begin: const Offset(0, .22), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(.2, .66, curve: Curves.easeOutCubic),
          ),
        );
    _taglineOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(.48, .9, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, .28), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(.46, .92, curve: Curves.easeOutCubic),
          ),
        );

    _introController.forward();
    _ambientController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionPreferenceApplied) return;
    _motionPreferenceApplied = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _introController.value = 1;
      _ambientController
        ..stop()
        ..value = .5;
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ambientController,
            builder: (context, child) {
              final progress = _ambientController.value;
              return Transform.translate(
                offset: Offset(-4 + (8 * progress), -2 + (4 * progress)),
                child: child,
              );
            },
            child: Image.asset(
              AppAssets.splashBackground,
              alignment: Alignment.topCenter,
              fit: BoxFit.none,
              repeat: ImageRepeat.repeat,
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The frame sits the group slightly below centre.
                  const SizedBox(height: 12),
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: SlideTransition(
                      position: _logoSlide,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: AnimatedBuilder(
                          animation: _ambientController,
                          builder: (context, child) => Transform.scale(
                            scale: .99 + (.02 * _ambientController.value),
                            child: child,
                          ),
                          child: Image(
                            image: const AssetImage(AppAssets.logo),
                            width: 45,
                            height: 61,
                            fit: BoxFit.contain,
                            semanticLabel: 'Zoovana logo'.tr,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FadeTransition(
                    opacity: _wordmarkOpacity,
                    child: SlideTransition(
                      position: _wordmarkSlide,
                      child: const Text(
                        'ZOOVANA',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 38,
                          height: 1.1,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: Text.rich(
                        TextSpan(
                          text: 'Feed street animals, '.tr,
                          children: [
                            TextSpan(
                              text: 'see every meal'.tr,
                              style: const TextStyle(color: AppColors.accent),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
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
}
