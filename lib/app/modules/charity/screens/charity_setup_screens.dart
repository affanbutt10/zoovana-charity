import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../home/screens/customer_shell_screen.dart';
import '../widgets/animal_visual.dart';

/// Customer navigation shown on the charity hub screens, with no tab active.
class CharityNavBar extends StatelessWidget {
  const CharityNavBar({super.key});

  @override
  Widget build(BuildContext context) => AppBottomNav(
    destinations: CustomerNav.destinations,
    selectedIndex: null,
    onSelected: CustomerTab.open,
    onCenterTap: () => Get.offNamedUntil(
      AppRoutes.charityLocation,
      ModalRoute.withName(AppRoutes.home),
    ),
  );
}

/// Photo card with a teal title, description and "Start now" action.
class CharityOptionCard extends StatelessWidget {
  const CharityOptionCard({
    super.key,
    required this.image,
    required this.title,
    required this.body,
    required this.onTap,
    this.button = 'Start now',
  });

  final String image;
  final String title;
  final String body;
  final String button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    shadow: true,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          image,
          height: 146,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.brand,
                  fontSize: 19.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 13.5, height: 1.25)),
              const SizedBox(height: 14),
              PillButton(label: button.tr, height: 34, onPressed: onTap),
            ],
          ),
        ),
      ],
    ),
  );
}

class CharitySupportScreen extends StatelessWidget {
  const CharitySupportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Support and donation'.tr),
    extendBody: true,
    bottomNavigationBar: const CharityNavBar(),
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        AppBottomNav.contentPadding(context),
      ),
      children: staggered([
        Text(
          'Select what you want to support and donate for'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        CharityOptionCard(
          image: AppAssets.charityStreet,
          title: 'Street Animals'.tr,
          body: 'Help stray animals access food, medical care, and rescue services in your community.'
              .tr,
          onTap: () => Get.toNamed(AppRoutes.charityLocation),
        ),
        const SizedBox(height: 18),
        CharityOptionCard(
          image: AppAssets.charityShelter,
          title: 'Shelters and Campaigns'.tr,
          body: 'Support animal shelters with the food, supplies, and care they need to protect animals.'
              .tr,
          onTap: () => Get.toNamed(AppRoutes.shelterHub),
        ),
      ]),
    ),
  );
}

/// City choice, built from the active programmes (`GET /programs`).
class CharityLocationScreen extends StatefulWidget {
  const CharityLocationScreen({super.key});

  @override
  State<CharityLocationScreen> createState() => _CharityLocationScreenState();
}

class _CharityLocationScreenState extends State<CharityLocationScreen> {
  List<CharityCampaign>? _programmes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final programmes = await Get.find<CharityRepository>().getCampaigns();
      if (mounted) setState(() => _programmes = programmes);
    } catch (error) {
      if (mounted) setState(() => _error = AppErrorMapper.map(error).message);
    }
  }

  /// Programmes grouped by city, in the order the API sorts them.
  Map<String, List<CharityCampaign>> get _cities {
    final cities = <String, List<CharityCampaign>>{};
    for (final programme in _programmes ?? const <CharityCampaign>[]) {
      final key = programme.cityCode.isEmpty
          ? programme.city
          : programme.cityCode;
      (cities[key] ??= []).add(programme);
    }
    return cities;
  }

  @override
  Widget build(BuildContext context) {
    final cities = _cities.values.toList(growable: false);
    return _ArtworkChoiceScaffold(
      question: 'Where do you want to donate ?'.tr,
      isLoading: _programmes == null && _error == null,
      error: _error,
      onRetry: _load,
      empty: 'No feeding programmes are open right now.'.tr,
      choices: [
        for (final (index, programmes) in cities.indexed)
          _cityChoice(programmes, mirror: index.isOdd),
      ],
    );
  }

  _ArtworkChoice _cityChoice(
    List<CharityCampaign> programmes, {
    required bool mirror,
  }) {
    final city = programmes.first;
    void open() => Get.toNamed(AppRoutes.charityAnimal, arguments: programmes);
    if (city.isMakkah) {
      return _ArtworkChoice(
        image: AppAssets.cityMakkah,
        label: 'city of makkah'.tr,
        faded: true,
        imageWidth: 283,
        imageTop: 16,
        imageRight: -38,
        labelStart: 16,
        onTap: open,
      );
    }
    final madinah = '${city.cityCode} ${city.city}'.toLowerCase().contains(
      'madin',
    );
    return _ArtworkChoice(
      image: madinah ? AppAssets.cityMadina : AppAssets.charityStreet,
      label: madinah
          ? 'city of madina'.tr
          : 'city of @city'.trParams({'city': city.city.toLowerCase()}),
      faded: true,
      imageWidth: 270,
      imageRight: -30,
      mirror: mirror,
      labelStart: 16,
      onTap: open,
    );
  }
}

/// Animal choice: one card per programme in the chosen city.
class CharityAnimalScreen extends StatelessWidget {
  const CharityAnimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    final programmes = arguments is List<CharityCampaign>
        ? arguments
        : const <CharityCampaign>[];
    return _ArtworkChoiceScaffold(
      question: 'What animal do you want to feed ?'.tr,
      empty: 'Choose a city first.'.tr,
      choices: [
        for (final programme in programmes)
          _ArtworkChoice(
            image: animalArt(programme.animalKind),
            label: _feedLabel(programme),
            onTap: () => Get.toNamed(AppRoutes.campaign, arguments: programme),
          ),
      ],
    );
  }

  /// "Feed Cats"; an animal type without its own key reads "Feed Turtles".
  static String _feedLabel(CharityCampaign programme) =>
      switch (programme.animalKind) {
        AnimalKind.cat => 'Feed Cats'.tr,
        AnimalKind.bird => 'Feed Birds'.tr,
        AnimalKind.dog => 'Feed Dogs'.tr,
        AnimalKind.other => 'Feed @animal'.trParams({
          'animal': programme.animal,
        }),
      };
}

class _ArtworkChoiceScaffold extends StatelessWidget {
  const _ArtworkChoiceScaffold({
    required this.question,
    required this.choices,
    required this.empty,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  final String question;
  final List<_ArtworkChoice> choices;
  final String empty;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Street Animals Support'.tr),
    body: AppStateView(
      isLoading: isLoading,
      error: error,
      onRetry: onRetry,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
        children: staggered([
          Text(
            question,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          if (choices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                empty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          for (var index = 0; index < choices.length; index++) ...[
            if (index > 0) const SizedBox(height: 18),
            choices[index],
          ],
        ]),
      ),
    ),
  );
}

/// Tall white card with a label + arrow over cut-out artwork.
class _ArtworkChoice extends StatelessWidget {
  const _ArtworkChoice({
    required this.image,
    required this.label,
    required this.onTap,
    this.faded = false,
    this.imageWidth = 230,
    this.imageTop,
    this.imageRight = 0,
    this.mirror = false,
    this.labelStart = 22,
  });

  /// Negative values let the artwork bleed past the card's end edge.
  final double imageRight;
  final bool mirror;

  final String image;
  final String label;
  final VoidCallback onTap;
  final bool faded;
  final double imageWidth;

  /// Pins the artwork's top edge and lets it run past the card's bottom;
  /// otherwise it sits on the bottom edge.
  final double? imageTop;
  final double labelStart;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 16,
    onTap: onTap,
    child: SizedBox(
      height: 286,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: CardSwirlPainter()),
          PositionedDirectional(
            end: imageRight,
            top: imageTop,
            bottom: imageTop == null ? 0 : null,
            width: imageWidth,
            height: imageTop == null ? 358 : null,
            child: Opacity(
              opacity: faded ? .5 : 1,
              child: Transform.flip(
                flipX: mirror,
                child: Image.asset(
                  image,
                  fit: imageTop == null ? BoxFit.contain : BoxFit.fitWidth,
                  alignment: imageTop == null
                      ? AlignmentDirectional.bottomEnd
                      : AlignmentDirectional.topEnd,
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: labelStart,
            top: 33,
            child: Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.brand,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
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

/// Faint teal ovals behind the artwork on white choice cards.
class CardSwirlPainter extends CustomPainter {
  const CardSwirlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1200A7A7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawOval(
      Rect.fromLTWH(-size.width * .35, 30, size.width * 1.05, 150),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * .25, -60, size.width * .55, 220),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
