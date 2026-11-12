import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One sweep per layout, with animation paused for hidden tabs and accessibility.
class DonorShimmer extends StatefulWidget {
  const DonorShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<DonorShimmer> createState() => _DonorShimmerState();
}

class _DonorShimmerState extends State<DonorShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading'.tr,
    liveRegion: true,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.modulate,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment(-3 + _controller.value * 4, -.2),
              end: Alignment(-1 + _controller.value * 4, .2),
              colors: const [
                Color(0xFFE5EBEB),
                Color(0xFFF8FAFA),
                Color(0xFFE5EBEB),
              ],
              stops: const [0, .5, 1],
            ).createShader(bounds),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
  });
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE5EBEB),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Matching photo, copy, price and selection control for food packages.
class PackageListShimmer extends StatelessWidget {
  const PackageListShimmer({super.key});
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SkeletonBlock(height: 34),
        const SizedBox(height: 42),
        const SkeletonBlock(height: 38, radius: 24),
        const SizedBox(height: 20),
        for (var i = 0; i < 4; i++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SkeletonBlock(width: 82, height: 90, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(height: 16),
                      SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: .8,
                        child: SkeletonBlock(),
                      ),
                      SizedBox(height: 12),
                      SkeletonBlock(width: 70, height: 20),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                SkeletonBlock(width: 26, height: 26, radius: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    ),
  );
}

/// The large alternating city/animal artwork cards.
class LocationListShimmer extends StatelessWidget {
  const LocationListShimmer({super.key});
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SkeletonBlock(width: 230, height: 18),
        const SizedBox(height: 22),
        for (var i = 0; i < 2; i++) ...[
          Container(
            height: 245,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: i.isEven ? Alignment.topLeft : Alignment.topRight,
                  child: const SkeletonBlock(width: 110, height: 18),
                ),
                Align(
                  alignment: i.isEven
                      ? Alignment.bottomRight
                      : Alignment.bottomLeft,
                  child: const SkeletonBlock(
                    width: 160,
                    height: 175,
                    radius: 70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
      ],
    ),
  );
}

/// Status badge, request title, amount, timestamp and thumbnail.
class RequestListShimmer extends StatelessWidget {
  const RequestListShimmer({super.key, this.count = 3});
  final int count;
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: 44, height: 44, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(width: 76, height: 22, radius: 12),
                      SizedBox(height: 12),
                      SkeletonBlock(height: 16),
                      SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: .7,
                        child: SkeletonBlock(),
                      ),
                      SizedBox(height: 10),
                      SkeletonBlock(width: 110, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Horizontal programme cards use image-shaped placeholders above two lines.
class ProgrammeListShimmer extends StatelessWidget {
  const ProgrammeListShimmer({super.key, this.highlights = false});
  final bool highlights;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 172,
    child: DonorShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => SizedBox(
          width: (MediaQuery.sizeOf(context).width * .67).clamp(180, 280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBlock(
                height: highlights ? 108 : 90,
                radius: highlights ? 12 : 30,
              ),
              const SizedBox(height: 12),
              const SkeletonBlock(height: 16),
              const SizedBox(height: 8),
              const SkeletonBlock(width: 100),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Notification-specific icon, multiline message and trailing time/read marker.
class NotificationListShimmer extends StatelessWidget {
  const NotificationListShimmer({
    super.key,
    this.count = 5,
    this.scrollable = true,
  });
  final int count;
  final bool scrollable;
  @override
  Widget build(BuildContext context) {
    final content = DonorShimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBlock(width: 42, height: 42, radius: 12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBlock(height: 14),
                        SizedBox(height: 8),
                        SkeletonBlock(),
                        SizedBox(height: 8),
                        SkeletonBlock(width: 65, height: 10),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  SkeletonBlock(width: 8, height: 8, radius: 8),
                ],
              ),
            ),
        ],
      ),
    );
    return scrollable
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: content,
          )
        : content;
  }
}

class RequestDetailsShimmer extends StatelessWidget {
  const RequestDetailsShimmer({super.key});
  @override
  Widget build(BuildContext context) => DonorShimmer(child: ListView(padding: EdgeInsets.zero, children: [
    const SkeletonBlock(height: 200, radius: 0),
    Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SkeletonBlock(height: 22), const SizedBox(height: 12),
      const SkeletonBlock(width: 150), const SizedBox(height: 20),
      for (var i = 0; i < 3; i++) ...[
        Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonBlock(width: 140, height: 16), const SizedBox(height: 20),
            if (i == 1) const Row(children: [SkeletonBlock(width: 74, height: 74, radius: 12), SizedBox(width: 12),
              Expanded(child: Column(children: [SkeletonBlock(height: 16), SizedBox(height: 12), SkeletonBlock(height: 12)]))])
            else for (var j = 0; j < 3; j++) const Padding(padding: EdgeInsets.only(bottom: 18),
              child: Row(children: [Expanded(child: SkeletonBlock(height: 12)), SizedBox(width: 40), Expanded(child: SkeletonBlock(height: 12))])),
          ])),
        const SizedBox(height: 16),
      ],
    ])),
  ]));
}

class HomeCaseShimmer extends StatelessWidget {
  const HomeCaseShimmer({super.key});
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(height: 24),
          SizedBox(height: 12),
          SkeletonBlock(width: 150),
          SizedBox(height: 12),
          SkeletonBlock(width: 110),
          SizedBox(height: 65),
          SkeletonBlock(height: 75, radius: 14),
        ],
      ),
    ),
  );
}

class CityGridShimmer extends StatelessWidget {
  const CityGridShimmer({super.key});
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: Row(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(height: 105, radius: 12),
                SizedBox(height: 12),
                SkeletonBlock(height: 20),
                SizedBox(height: 8),
                SkeletonBlock(width: 100),
                SizedBox(height: 12),
                SkeletonBlock(width: 70, height: 18),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class ImpactSummaryShimmer extends StatelessWidget {
  const ImpactSummaryShimmer({super.key});
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(height: 28, radius: 8),
                SizedBox(height: 12),
                SkeletonBlock(height: 14),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class VerifiedFeedingListShimmer extends StatelessWidget {
  const VerifiedFeedingListShimmer({super.key});
  @override
  Widget build(BuildContext context) => DonorShimmer(
    child: Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          const SkeletonBlock(height: 145, radius: 14),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: SkeletonBlock(height: 18)),
              SizedBox(width: 30),
              SkeletonBlock(width: 60, height: 20),
            ],
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkeletonBlock(width: 150),
          ),
          const SizedBox(height: 14),
          const SkeletonBlock(height: 48, radius: 10),
          const SizedBox(height: 14),
          const SkeletonBlock(height: 36, radius: 24),
          const SizedBox(height: 24),
        ],
      ],
    ),
  );
}

class PackageGridShimmer extends StatelessWidget {
  const PackageGridShimmer({super.key});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: DonorShimmer(
      child: LayoutBuilder(
        builder: (context, box) {
          final columns = box.maxWidth >= 600 ? 3 : 2;
          final width = (box.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              for (var i = 0; i < 6; i++)
                SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBlock(height: width / 1.35, radius: 12),
                      const SizedBox(height: 10),
                      const SkeletonBlock(height: 16),
                      const SizedBox(height: 8),
                      const SkeletonBlock(height: 12),
                      const SizedBox(height: 12),
                      const SkeletonBlock(width: 65, height: 20),
                      const Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: SkeletonBlock(width: 22, height: 22, radius: 22),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
