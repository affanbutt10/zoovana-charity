import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/assets/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/repositories/community_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../charity/screens/charity_setup_screens.dart';
import '../../charity/screens/shelter_screens.dart';

class AdoptionPet {
  const AdoptionPet({
    required this.name,
    required this.breed,
    required this.gender,
    required this.bornOn,
    required this.weight,
    required this.height,
    required this.repro,
    required this.kind,
    required this.image,
    required this.description,
  });

  final String name;
  final String breed;
  final String gender;
  final String bornOn;
  final String weight;
  final String height;
  final String repro;

  /// Filter group: `Dogs` or `Cats`.
  final String kind;
  final String image;
  final String description;

  String get favoriteId => 'pet:$name';
}

const adoptionPets = <AdoptionPet>[
  AdoptionPet(
    name: 'Bites',
    breed: 'Golden Retriever',
    gender: 'Male',
    bornOn: '22-2-2025',
    weight: '3.5 kg',
    height: '133 cm',
    repro: 'neutered',
    kind: 'Dogs',
    image: AppAssets.petRiver,
    description:
        'Bites is a playful retriever who loves the beach, long walks and '
        'meeting new people. He is fully vaccinated, walks calmly on a lead '
        'and gets along with other dogs.',
  ),
  AdoptionPet(
    name: 'Luna',
    breed: 'Domestic Shorthair',
    gender: 'Female',
    bornOn: '4-1-2025',
    weight: '2.8 kg',
    height: '24 cm',
    repro: 'spayed',
    kind: 'Cats',
    image: AppAssets.adoptionKitten,
    description:
        'Luna is a curious young cat who loves sunny windows, soft toys and '
        'quiet company. She is litter trained and fully vaccinated.',
  ),
  AdoptionPet(
    name: 'Milo',
    breed: 'Golden Retriever',
    gender: 'Male',
    bornOn: '10-6-2024',
    weight: '12 kg',
    height: '52 cm',
    repro: 'neutered',
    kind: 'Dogs',
    image: AppAssets.shelterPuppy,
    description:
        'Milo is gentle and happiest around people. He knows basic cues and '
        'is ready for a family with a garden.',
  ),
];

/// "Adopt Animals": partner shelters that have animals for adoption.
class AdoptionBrowseScreen extends StatelessWidget {
  const AdoptionBrowseScreen({super.key});

  static const _images = [
    AppAssets.shelterPuppy,
    AppAssets.shelterFeeding,
    AppAssets.shelterKennels,
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const ZoovanaAppBar(title: 'Adopt Animals', light: true),
    extendBody: true,
    bottomNavigationBar: const CharityNavBar(),
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        AppBottomNav.contentPadding(context),
      ),
      children: staggered([
        const Text(
          'Adoption Animal From Shelters',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        const Text(
          'Hand-vetted companions waiting for their forever family.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 18),
        const SearchPill(fill: Color(0xFFF2F2F2)),
        const SizedBox(height: 19),
        const Text(
          'Shelters :',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        for (final image in _images) ...[
          ShelterCard(
            image: image,
            showLogo: false,
            actionLabel: 'Show details',
            onTap: () => Get.toNamed(AppRoutes.adoptionShelter),
            onAction: () => Get.toNamed(AppRoutes.adoptionShelter),
          ),
          const SizedBox(height: 17),
        ],
      ]),
    ),
  );
}

/// Shelter profile with its adoptable animals; the filter and search stay
/// pinned under the app bar while the list scrolls.
class AdoptionShelterScreen extends StatefulWidget {
  const AdoptionShelterScreen({super.key});

  @override
  State<AdoptionShelterScreen> createState() => _AdoptionShelterScreenState();
}

class _AdoptionShelterScreenState extends State<AdoptionShelterScreen> {
  int filter = 0;
  String query = '';
  final _scroll = ScrollController();
  final _sectionKey = GlobalKey();

  /// Once the "Shelter Animals" section reaches the app bar, a pinned copy
  /// with the search field takes its place, as in the scrolled frame.
  bool pinned = false;

  static const _filters = ['All Pets', 'Dogs', 'Cats'];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updatePinned);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scroll offset at which the section reaches the app bar, measured from
  /// the hero above it while that is still laid out.
  double? _sectionOffset;

  void _updatePinned() {
    final hero = _sectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (hero != null && hero.attached && _sectionOffset == null) {
      _sectionOffset = hero.size.height;
    }
    final threshold = _sectionOffset;
    if (threshold == null) return;
    final next = _scroll.offset >= threshold;
    if (next != pinned) setState(() => pinned = next);
  }

  @override
  Widget build(BuildContext context) {
    final pets = adoptionPets.where((pet) {
      final matchesKind = filter == 0 || pet.kind == _filters[filter];
      final text = '${pet.name} ${pet.breed}'.toLowerCase();
      return matchesKind && text.contains(query.trim().toLowerCase());
    }).toList();
    final counts = {
      for (final kind in const ['Dogs', 'Cats'])
        kind: adoptionPets.where((pet) => pet.kind == kind).length,
    };
    final labels = [
      'All Pets',
      'Dogs (${counts['Dogs']})',
      'Cats (${counts['Cats']})',
    ];
    return Scaffold(
      appBar: const ZoovanaAppBar(title: 'Shelter Details', light: true),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: ShelterHero(
                  key: _sectionKey,
                  showActions: true,
                  trailing: ShelterInfoButton(
                    onTap: () => Get.toNamed(AppRoutes.shelterInfo),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 0, 24),
                  child: _AnimalsSection(
                    labels: labels,
                    selected: filter,
                    onSelected: (value) => setState(() => filter = value),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: pets.isEmpty ? 1 : pets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    if (pets.isEmpty) {
                      return const AppEntranceAnimation.pop(
                        child: Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Center(
                            child: Text(
                              'No animals match your search.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      );
                    }
                    final row = _AnimalRow(pet: pets[index]);
                    if (index >= 8) return row;
                    // Keyed by the filter so switching it cascades the list
                    // in again.
                    return AppEntranceAnimation(
                      key: ValueKey('$filter-$index'),
                      delay: AppMotion.stagger * math.min(index, 7),
                      duration: AppMotion.slow,
                      beginOffset: const Offset(0, .06),
                      child: row,
                    );
                  },
                ),
              ),
            ],
          ),
          if (pinned)
            Container(
              width: double.infinity,
              color: AppColors.surfaceBase,
              padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimalsSection(
                    labels: labels,
                    selected: filter,
                    onSelected: (value) => setState(() => filter = value),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(right: 20, left: 4),
                    child: SearchPill(
                      onChanged: (value) => setState(() => query = value),
                      fill: const Color(0xFFF2F2F2),
                    ),
                  ),
                  const SizedBox(height: 19),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimalsSection extends StatelessWidget {
  const _AnimalsSection({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Shelter Animals :',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 17),
      FilterPills(labels: labels, selected: selected, onSelected: onSelected),
    ],
  );
}

class _AnimalRow extends StatelessWidget {
  const _AnimalRow({required this.pet});
  final AdoptionPet pet;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 8,
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
    onTap: () => Get.toNamed(AppRoutes.adoptionDetails, arguments: pet),
    child: SizedBox(
      height: 61,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                pet.image,
                width: 66,
                height: 55,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 78,
            top: 0,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  pet.breed,
                  style: const TextStyle(fontSize: 12.5, height: 1.2),
                ),
                const SizedBox(height: 7),
                Text(
                  'Gender : ${pet.gender.toLowerCase()} - born on : ${pet.bornOn}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    color: Color(0xFF8E8E8E),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: -2,
            child: FavoriteButton(
              id: pet.favoriteId,
              background: const Color(0xFFF7F7F7),
              size: 24,
            ),
          ),
        ],
      ),
    ),
  );
}

class AdoptionPetDetailsScreen extends StatefulWidget {
  const AdoptionPetDetailsScreen({super.key});

  @override
  State<AdoptionPetDetailsScreen> createState() =>
      _AdoptionPetDetailsScreenState();
}

class _AdoptionPetDetailsScreenState extends State<AdoptionPetDetailsScreen> {
  int page = 0;
  late final AdoptionPet pet = Get.arguments is AdoptionPet
      ? Get.arguments as AdoptionPet
      : adoptionPets.first;

  @override
  Widget build(BuildContext context) {
    final facts = [
      (AppIcons.detailBreed, 'Breed', pet.breed),
      (AppIcons.detailGender, 'Gender', pet.gender),
      (AppIcons.detailBorn, 'Born on', pet.bornOn),
      (AppIcons.detailWeight, 'Weight', pet.weight),
      (AppIcons.detailHeight, 'Height', pet.height),
      (AppIcons.detailRepro, 'Repro Status', pet.repro),
    ];
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Pet Details', light: true),
      bottomNavigationBar: BottomActionBar(
        flexes: const [2, 5],
        children: [
          Semantics(
            label: 'Call shelter',
            child: PillButton(
              label: '',
              style: PillButtonStyle.muted,
              icon: const Icon(
                Icons.phone_outlined,
                color: AppColors.brand,
                size: 24,
              ),
              onPressed: () =>
                  Get.snackbar('Contact', 'Calling Small paw shelter…'),
            ),
          ),
          PillButton(
            label: 'Schedule meet-up',
            onPressed: () =>
                Get.toNamed(AppRoutes.adoptionApply, arguments: pet),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 199,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: 3,
                  onPageChanged: (value) => setState(() => page = value),
                  itemBuilder: (_, _) =>
                      Image.asset(pet.image, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 16,
                  top: 12,
                  child: FavoriteButton(id: pet.favoriteId),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          curve: AppMotion.curve,
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: i == page ? AppColors.accent : Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: staggered([
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(pet.image),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'About Pet :',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                SurfaceCard(
                  radius: 8,
                  child: Column(
                    children: [
                      for (final (index, fact) in facts.indexed) ...[
                        if (index > 0)
                          const Divider(height: 1, color: Color(0xFFEDEDED)),
                        SizedBox(
                          height: 36,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                AssetIcon(
                                  fact.$1,
                                  color: AppColors.accent,
                                  size: 21,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${fact.$2} :',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    fact.$3,
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Meet ${pet.name} :',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pet.description,
                  style: const TextStyle(fontSize: 14, height: 1.2),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Book a date": pick a day, a time slot and leave notes for the meet-up.
class AdoptionApplicationScreen extends StatefulWidget {
  const AdoptionApplicationScreen({super.key});

  @override
  State<AdoptionApplicationScreen> createState() =>
      _AdoptionApplicationScreenState();
}

class _AdoptionApplicationScreenState extends State<AdoptionApplicationScreen> {
  static const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  static const _slots = [
    ('MORNING', AppIcons.morning, Color(0xFFF2A93B), ['09:30 AM', '11:00 AM']),
    (
      'AFTERNOON',
      AppIcons.afternoon,
      Color(0xFFF2A93B),
      ['01:30 PM', '03:15 PM', '04:45 PM'],
    ),
    ('EVENING', AppIcons.evening, Color(0xFF7C83E8), ['06:00 PM']),
  ];

  /// Slots already taken by another visitor.
  static const _booked = {'09:30 AM'};

  late final AdoptionPet pet = Get.arguments is AdoptionPet
      ? Get.arguments as AdoptionPet
      : adoptionPets.first;
  final today = DateUtils.dateOnly(DateTime.now());
  late DateTime date = today;
  String time = '03:15 PM';
  final notesController = TextEditingController();

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCalendar() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _book() async {
    await Get.find<CommunityRepository>().submitAdoptionApplication(pet.name);
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0x1A000000),
      pageBuilder: (context, _, _) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            child: const SizedBox(
              width: 304,
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 36, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.tick_circle_copy,
                      color: Color(0xFF29A745),
                      size: 64,
                    ),
                    SizedBox(height: 14),
                    Text('Thank you!', style: TextStyle(fontSize: 20)),
                    SizedBox(height: 18),
                    Text(
                      'Your meet-up has been scheduled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final dates = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Book a date', light: true),
      bottomNavigationBar: BottomActionBar(
        children: [PillButton(label: 'Book now', onPressed: _book)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 0, 24),
        children: staggered([
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: SectionHeader(
              title: 'Select Date :',
              titleSize: 19,
              action: 'View Calendar',
              actionSize: 15,
              onAction: _pickFromCalendar,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final day = dates[index];
                final selected = DateUtils.isSameDay(day, date);
                return _DateChip(
                  weekday: _weekdays[day.weekday - 1],
                  day: day.day,
                  selected: selected,
                  onTap: () => setState(() => date = day),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Select Time Available :',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          for (final (index, group) in _slots.indexed) ...[
            SizedBox(height: index == 0 ? 12 : 15),
            Row(
              children: [
                AssetIcon(group.$2, size: 16, color: group.$3),
                const SizedBox(width: 8),
                Text(
                  group.$1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 11,
              runSpacing: 11,
              children: [
                for (final slot in group.$4)
                  _TimeSlot(
                    label: slot,
                    selected: slot == time,
                    disabled: _booked.contains(slot),
                    onTap: () => setState(() => time = slot),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            'Notes for your meeting :',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: TextField(
              controller: notesController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter Notes....',
                hintStyle: const TextStyle(
                  color: Color(0xFFA3A3A3),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: _notesBorder,
                enabledBorder: _notesBorder,
                focusedBorder: _notesBorder.copyWith(
                  borderSide: const BorderSide(color: AppColors.brand),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  static final _notesBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: Color(0xFFDADADA)),
  );
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.weekday,
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final String weekday;
  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AppPressable(
      pressedScale: .94,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          width: 72,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.accent : const Color(0xFFEAEAEA),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TimeSlot extends StatelessWidget {
  const _TimeSlot({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    enabled: !disabled,
    button: true,
    child: AppPressable(
      enabled: !disabled,
      pressedScale: .94,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          width: 102,
          height: 41,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: disabled
                ? const Color(0xFFEEF2FB)
                : selected
                ? AppColors.accent
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: disabled
                  ? const Color(0xFFEEF2FB)
                  : selected
                  ? AppColors.accent
                  : const Color(0xFFEAEAEA),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x33F15C61),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: disabled
                  ? const Color(0xFFB8BCC6)
                  : selected
                  ? Colors.white
                  : AppColors.textPrimary,
              decoration: disabled ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    ),
  );
}
