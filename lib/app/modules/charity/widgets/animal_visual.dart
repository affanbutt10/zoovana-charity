import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../data/models/charity_campaign.dart';

/// Cut-out artwork for a programme's animal.
String animalArt(AnimalKind kind) => switch (kind) {
  AnimalKind.bird => AppAssets.animalBird,
  AnimalKind.dog => AppAssets.petTypeDog,
  _ => AppAssets.animalCat,
};

/// The bundled skyline for a city, or null when the app has none.
String? citySkyline(String city) {
  final name = city.toLowerCase();
  if (name.contains('mak')) return AppAssets.cityMakkah;
  if (name.contains('madin')) return AppAssets.cityMadina;
  return null;
}

class AnimalVisual extends StatelessWidget {
  const AnimalVisual({
    super.key,
    required this.kind,
    required this.color,
    this.size = 120,
  });

  final AnimalKind kind;
  final Color color;
  final double size;

  IconData get _icon => switch (kind) {
    AnimalKind.cat => Icons.pets_rounded,
    AnimalKind.bird => Icons.flutter_dash_rounded,
    AnimalKind.dog => Icons.cruelty_free_rounded,
    AnimalKind.other => Icons.pets_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(
        _icon,
        size: size * .48,
        color: color,
        shadows: const [
          Shadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

Color campaignColor(CharityCampaign campaign) => switch (campaign.animalKind) {
  AnimalKind.cat when campaign.city == 'Makkah' => const Color(0xFF126E5A),
  AnimalKind.cat => const Color(0xFF8B5E34),
  AnimalKind.bird => const Color(0xFF1F6E9C),
  AnimalKind.dog => const Color(0xFF7C4D9F),
  AnimalKind.other => const Color(0xFF126E5A),
};
