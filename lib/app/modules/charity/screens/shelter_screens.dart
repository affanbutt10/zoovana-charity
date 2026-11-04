import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/assets/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/zoovana_ui.dart';

const _shelterFavoriteId = 'shelter:small-paw';
const shelterName = 'Small paw shelter';
const shelterLocation = 'Green Valley Rescue • 3.5 km away';
const _campaignBody =
    'Support animal shelters with the food, supplies, and care they need to protect animals.';

void _donateToShelter() => Get.toNamed(
  AppRoutes.campaign,
  arguments: const CharityCampaign(
    id: 'small-paw-shelter',
    title: 'Donate to Small paw shelter',
    city: 'Green Valley',
    animal: 'Shelter animals',
    animalKind: AnimalKind.dog,
    description: 'Provide food and daily-care supplies to rescued animals at a verified Zoovana partner shelter.',
    supporters: 638,
    kind: CampaignKind.shelter,
  ),
);

/// Shelter donation landing: banner, partner shelters and active campaigns.
class ShelterHubScreen extends StatelessWidget {
  const ShelterHubScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Donate for Shelters'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: staggered([
        const PromoCard(
          actionLabel: 'Donate to shelter',
          onAction: _donateToShelter,
        ),
        const SizedBox(height: 14),
        Transform.translate(
          offset: const Offset(-24, 0),
          child: const Center(
            child: Icon(Icons.circle, size: 7, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Donate for shelters',
          onAction: () => Get.toNamed(AppRoutes.shelters),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (_, _) => AppPressable(
              pressedScale: .94,
              child: GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.shelterDetails),
                child: const Column(
                  children: [
                    ShelterLogoCircle(size: 58),
                    SizedBox(height: 10),
                    Text('Small paw', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
        SectionHeader(
          title: 'Active Campaigns',
          onAction: () => Get.toNamed(AppRoutes.shelterCampaigns),
        ),
        const SizedBox(height: 14),
        const _CampaignCard(),
      ]),
    ),
  );
}

class ShelterLogoCircle extends StatelessWidget {
  const ShelterLogoCircle({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .14),
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFF0F0F0)),
    ),
    child: ClipOval(child: Image.asset(AppAssets.shelterLogo)),
  );
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard();

  @override
  Widget build(BuildContext context) => SurfaceCard(
    shadow: true,
    onTap: () => Get.toNamed(AppRoutes.shelterDetails),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          AppAssets.shelterPuppy,
          height: 146,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  ShelterLogoCircle(size: 34),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      shelterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '$_campaignBody$_campaignBody',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, height: 1.3),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                ),
                child: const Text(
                  'Need : 3 packages of dogs medicine',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              const PillButton(
                label: 'Donate Now',
                height: 34,
                onPressed: _donateToShelter,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class RatingPill extends StatelessWidget {
  const RatingPill({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: 13, color: AppColors.star),
        SizedBox(width: 2),
        Text('4.5', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

/// White heart toggle persisted in the account favorites.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    this.id = _shelterFavoriteId,
    this.background = Colors.white,
    this.size = 32,
  });

  final String id;
  final Color background;
  final double size;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  AccountRepository get _repository => Get.find<AccountRepository>();

  @override
  Widget build(BuildContext context) {
    final selected = _repository.isFavorite(widget.id);
    return Semantics(
      button: true,
      label: selected ? 'Remove from favorites' : 'Add to favorites',
      child: AppPressable(
        pressedScale: .9,
        child: GestureDetector(
          onTap: () async {
            await _repository.toggleFavorite(widget.id);
            if (mounted) setState(() {});
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.background,
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.spring,
              switchOutCurve: AppMotion.curve,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.passthrough,
                alignment: Alignment.center,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                selected ? Icons.favorite_rounded : Iconsax.heart_copy,
                key: ValueKey(selected),
                size: widget.size * .6,
                color: selected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SheltersScreen extends StatefulWidget {
  const SheltersScreen({super.key});

  @override
  State<SheltersScreen> createState() => _SheltersScreenState();
}

class _SheltersScreenState extends State<SheltersScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches =
        query.trim().isEmpty ||
        '$shelterName $shelterLocation'.toLowerCase().contains(
          query.trim().toLowerCase(),
        );
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Shelters'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: staggered([
          const Text(
            'All Shelters :',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SearchPill(onChanged: (value) => setState(() => query = value)),
          const SizedBox(height: 24),
          if (matches)
            for (final image in const [
              AppAssets.shelterPuppy,
              AppAssets.shelterFeeding,
              AppAssets.shelterKennels,
            ]) ...[ShelterCard(image: image), const SizedBox(height: 18)]
          else
            const Padding(
              padding: EdgeInsets.only(top: 64),
              child: Center(
                child: Text(
                  'No shelters match your search.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Shelter photo card with rating, favorite, name, distance and an action.
class ShelterCard extends StatelessWidget {
  const ShelterCard({
    super.key,
    this.image = AppAssets.shelterPuppy,
    this.actionLabel = 'Donate now',
    this.onAction = _donateToShelter,
    this.onTap,
    this.showLogo = true,
  });

  final String image;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTap;
  final bool showLogo;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    shadow: true,
    onTap: onTap ?? () => Get.toNamed(AppRoutes.shelterDetails),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 146,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(image, fit: BoxFit.cover),
              const Positioned(left: 12, top: 14, child: RatingPill()),
              const Positioned(right: 10, top: 12, child: FavoriteButton()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showLogo) ...[
                    const ShelterLogoCircle(size: 34),
                    const SizedBox(width: 8),
                  ],
                  const Flexible(
                    child: Text(
                      shelterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const IconLine(
                icon: Iconsax.location_copy,
                text: shelterLocation,
                size: 15,
                iconSize: 16,
                color: Color(0xFF555B61),
              ),
              const SizedBox(height: 18),
              PillButton(label: actionLabel, height: 34, onPressed: onAction),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Campaign listing reached from "Active Campaigns".
class ShelterCampaignsScreen extends StatelessWidget {
  const ShelterCampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Campaigns'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: staggered([
        const Text(
          'All Campaigns :',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const SearchPill(),
        const SizedBox(height: 24),
        for (var i = 0; i < 3; i++) ...[
          const _CampaignCard(),
          const SizedBox(height: 18),
        ],
      ]),
    ),
  );
}

/// Hero photo, overlapping logo tile, name and partner badge.
class ShelterHero extends StatelessWidget {
  const ShelterHero({super.key, this.trailing, this.showActions = false});
  final Widget? trailing;
  final bool showActions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 236,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              bottom: 36,
              child: Image.asset(AppAssets.shelterPuppy, fit: BoxFit.cover),
            ),
            if (showActions) ...[
              const Positioned(left: 12, top: 12, child: RatingPill()),
              const Positioned(right: 16, top: 12, child: FavoriteButton()),
            ],
            Positioned(
              left: 20,
              bottom: 0,
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(AppAssets.shelterLogo),
              ),
            ),
            if (trailing != null)
              Positioned(right: 20, bottom: -8, child: trailing!),
          ],
        ),
      ),
      const SizedBox(height: 15),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    shelterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF2BB673),
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: 4),
            _PartnerBadge(),
          ],
        ),
      ),
    ],
  );
}

/// Teal "Check info" pill on the shelter hero.
class ShelterInfoButton extends StatelessWidget {
  const ShelterInfoButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    child: FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.only(left: 12, right: 14),
        textStyle: const TextStyle(
          fontFamily: 'Glory',
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      icon: const Icon(Iconsax.info_circle_copy, size: 20),
      label: const Text('Check info'),
    ),
  );
}

class ShelterDetailsScreen extends StatefulWidget {
  const ShelterDetailsScreen({super.key});

  @override
  State<ShelterDetailsScreen> createState() => _ShelterDetailsScreenState();
}

class _ShelterDetailsScreenState extends State<ShelterDetailsScreen> {
  bool showCampaigns = false;
  int petFilter = 0;

  static const _animals = [
    ('Bites', 'Golden Retriever', 'male', 'Dogs'),
    ('Milo', 'Mixed breed puppy', 'male', 'Dogs'),
    ('Luna', 'Domestic Shorthair', 'female', 'Cats'),
  ];

  @override
  Widget build(BuildContext context) {
    final animals = _animals.where(
      (animal) =>
          petFilter == 0 || animal.$4 == (petFilter == 1 ? 'Dogs' : 'Cats'),
    );
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Shelter details'),
      bottomNavigationBar: const BottomActionBar(
        children: [
          PillButton(label: 'Donate to Shelter', onPressed: _donateToShelter),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ShelterHero(
            showActions: true,
            trailing: ShelterInfoButton(
              onTap: () => Get.toNamed(AppRoutes.shelterInfo),
            ),
          ),
          ...staggered([
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final (index, label) in const [
                    'Campaigns',
                    'Shelter animals',
                  ].indexed) ...[
                    if (index > 0) const SizedBox(width: 16),
                    Expanded(
                      child: _SegmentButton(
                        label: label,
                        selected: showCampaigns == (index == 0),
                        onTap: () => setState(() => showCampaigns = index == 0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FadeSwitcher(
                child: showCampaigns
                    ? const Column(
                        key: ValueKey('campaigns'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Campaigns :',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 16),
                          _CampaignCard(),
                        ],
                      )
                    : Column(
                        key: const ValueKey('animals'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shelter Animals :',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilterPills(
                            labels: const [
                              'All Pets',
                              'Dogs (24)',
                              'Cats (16)',
                            ],
                            selected: petFilter,
                            onSelected: (value) =>
                                setState(() => petFilter = value),
                          ),
                          const SizedBox(height: 24),
                          _FadeSwitcher(
                            child: Column(
                              key: ValueKey(petFilter),
                              children: [
                                for (final animal in animals) ...[
                                  _AnimalRow(
                                    name: animal.$1,
                                    breed: animal.$2,
                                    gender: animal.$3,
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Cross-fades in-place content such as a selected segment or filter.
class _FadeSwitcher extends StatelessWidget {
  const _FadeSwitcher({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.medium,
    switchInCurve: AppMotion.curve,
    switchOutCurve: AppMotion.curve,
    layoutBuilder: pinnedSwitcherLayout,
    child: child,
  );
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AppPressable(
      pressedScale: .96,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.brand : const Color(0xFFE4E4E4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: selected ? AppColors.brand : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AnimalRow extends StatelessWidget {
  const _AnimalRow({
    required this.name,
    required this.breed,
    required this.gender,
  });

  final String name;
  final String breed;
  final String gender;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 8,
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
    onTap: () => Get.toNamed(AppRoutes.adoptionShelter),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            AppAssets.petRiver,
            width: 68,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(breed, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                'Gender : $gender - born on : 22-2-2025',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ShelterInfoScreen extends StatelessWidget {
  const ShelterInfoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Shelter Information'),
    body: ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const ShelterHero(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              const _InfoHeading(asset: AppIcons.store, title: 'About Shelter'),
              const SizedBox(height: 9),
              const Text(
                'A verified community shelter providing safe housing, nutritious food, medical support, and adoption services for rescued animals. Every donation is tracked and shared with donors.',
                style: TextStyle(fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 15),
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(10, 14, 16, 14),
                onTap: () =>
                    Get.toNamed(AppRoutes.ratings, arguments: 'Shelter Rating'),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoHeading(asset: AppIcons.rating, title: 'Rating'),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Text('4.5', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 6),
                              Icon(
                                Icons.star_rounded,
                                color: AppColors.star,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '+32 Reviews',
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: _InfoHeading(
                            asset: AppIcons.store,
                            title: 'Shelter Info & Operations',
                          ),
                        ),
                        AppPressable(
                          pressedScale: .94,
                          child: GestureDetector(
                            onTap: () => Get.snackbar(
                              'Contact',
                              'Calling Small paw shelter…',
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Iconsax.call_copy,
                                  color: AppColors.brand,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Contact',
                                  style: TextStyle(
                                    color: AppColors.brand,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    const _OperationRow(
                      icon: Iconsax.location_copy,
                      title: '742 Evergreen Boulevard, Suite 104',
                      subtitle: 'Oakridge District • Curbside pickup available',
                    ),
                    const SizedBox(height: 9),
                    const _OperationRow(
                      icon: Iconsax.clock_copy,
                      overline: 'Open now',
                      title: 'Today: 08:30 AM – 09:00 PM',
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    ),
  );
}

class _InfoHeading extends StatelessWidget {
  const _InfoHeading({required this.asset, required this.title});
  final String asset;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AssetIcon(asset, color: AppColors.accent, size: 20),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.overline,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? overline;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEAEAEA)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16.5,
          backgroundColor: AppColors.accent,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overline != null)
                Text(
                  overline!,
                  style: const TextStyle(
                    color: Color(0xFF2BB673),
                    fontSize: 12,
                  ),
                ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
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
  );
}

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  int filter = 0;

  static const _reviews = [4, 4, 5, 3, 4];

  @override
  Widget build(BuildContext context) {
    final title = Get.arguments is String ? Get.arguments as String : 'Ratings';
    final stars = [null, 4, 3, 2, 1][filter];
    final reviews = _reviews.where((value) => stars == null || value == stars);
    return Scaffold(
      appBar: ZoovanaAppBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: [
          ...staggered([
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _RatingBars()),
                SizedBox(width: 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('4.5', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          color: AppColors.star,
                          size: 22,
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text('273 REVIEWS', style: _summaryCaption),
                    SizedBox(height: 18),
                    Text('88%', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 2),
                    Text('RECOMMENDED', style: _summaryCaption),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Rating and Reviews :',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            FilterPills(
              labels: const [
                'All Stars',
                '4 stars',
                '3 stars',
                '2 stars',
                '1 star',
              ],
              selected: filter,
              onSelected: (value) => setState(() => filter = value),
            ),
          ]),
          const SizedBox(height: 18),
          for (final (index, value) in reviews.indexed) ...[
            // Keyed by filter so switching it replays the cascade.
            AppEntranceAnimation(
              key: ValueKey('$filter/$index'),
              delay: AppMotion.stagger * (index + 1),
              duration: AppMotion.slow,
              beginOffset: const Offset(0, .06),
              child: _ReviewCard(stars: value),
            ),
            const SizedBox(height: 10),
          ],
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No reviews with this rating yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _summaryCaption = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
  color: AppColors.textSecondary,
);

class _RatingBars extends StatelessWidget {
  const _RatingBars();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in const [(5, 1.0), (4, .8), (3, .6), (2, .4), (1, .2)])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 14,
                child: Text(
                  '${item.$1}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: item.$2),
                  duration: const Duration(milliseconds: 900),
                  curve: AppMotion.curve,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE6E6E6),
                    color: AppColors.star,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.stars});
  final int stars;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool expanded = false;

  static const _body =
      'The team was kind, responsive, and transparent. The animals are well cared for, the shelter is clean, and every donation update came with clear photos. Donating supplies here was easy and I could see exactly where the food went.';

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < widget.stars
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: i < widget.stars
                      ? AppColors.star
                      : AppColors.textTertiary,
                ),
              ),
            const Spacer(),
            const Text('11/04/2024', style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => expanded = !expanded),
          child: Text.rich(
            TextSpan(
              text: expanded ? _body : '${_body.substring(0, 150)}..',
              children: [
                TextSpan(
                  text: expanded ? ' Show Less' : ' Show More',
                  style: const TextStyle(color: AppColors.brand),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: AssetImage(AppAssets.reviewerAvatar),
            ),
            SizedBox(width: 8),
            Text(
              'Nasr Ragheb Essa',
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PartnerBadge extends StatelessWidget {
  const _PartnerBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(7, 1, 10, 1),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(100),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Iconsax.medal_copy, size: 14),
        SizedBox(width: 4),
        Text(
          'Official Zoovana Partner',
          style: TextStyle(
            fontSize: 12,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
