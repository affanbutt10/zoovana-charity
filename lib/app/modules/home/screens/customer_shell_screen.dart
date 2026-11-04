import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/services/app_locale.dart';
// Out of charity scope: only the commented-out reminders used these icons.
// import '../../../core/assets/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/models/donation_receipt.dart';
// Out of charity scope: pets and appointments.
// import '../../../data/models/pet_profile.dart';
// import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/feeder_repository.dart';
// import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/shell_router.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../charity/screens/charity_setup_screens.dart';
import '../../charity/widgets/animal_visual.dart';
import '../../history/screens/donation_history_screen.dart';

/// Customer tabs addressable through the home route's arguments.
abstract final class CustomerTab {
  static const home = 0;
  static const requests = 1;
  static const impact = 2;
  static const profile = 3;
  // Out of charity scope:
  // static const pets = 1;
  // static const services = 2;

  /// Navigation used by screens outside the shell that show the customer bar.
  static void open(int index) =>
      Get.offAllNamed(AppRoutes.home, arguments: index);
}

class CustomerShellScreen extends StatefulWidget {
  const CustomerShellScreen({super.key});

  @override
  State<CustomerShellScreen> createState() => _CustomerShellScreenState();
}

class _CustomerShellScreenState extends State<CustomerShellScreen> {
  int _index = CustomerTab.home;
  List<DonationReceipt> _donations = const [];
  List<CharityCampaign> _programmes = const [];
  List<FeedingHighlight> _highlights = const [];
  bool _hasMoreRequests = false;

  @override
  void initState() {
    super.initState();
    final initial = Get.arguments;
    if (initial is int && initial >= 0 && initial <= CustomerTab.profile) {
      _index = initial;
    }
    _loadDonations();
    _refreshDonations();
    _loadProgrammes();
  }

  void _loadDonations() {
    if (!Get.isRegistered<CharityRepository>()) return;
    final repository = Get.find<CharityRepository>();
    setState(() {
      _donations = repository.getDonationHistory();
      _hasMoreRequests = repository.hasMoreHistory;
    });
  }

  /// Pulls the latest status of requests that are still in progress.
  Future<void> _refreshDonations() async {
    if (!Get.isRegistered<CharityRepository>()) return;
    try {
      await Get.find<CharityRepository>().refreshDonationHistory();
      if (mounted) _loadDonations();
    } catch (_) {
      // Cached statuses stay on screen until the next refresh succeeds.
    }
  }

  Future<void> _openRequest(DonationReceipt request) async {
    await Get.toNamed<dynamic>(AppRoutes.requestDetails, arguments: request);
    if (mounted) _loadDonations();
  }

  Future<void> _loadProgrammes() async {
    if (!Get.isRegistered<CharityRepository>()) return;
    try {
      final repository = Get.find<CharityRepository>();
      final programmes = await repository.getCampaigns();
      if (mounted) setState(() => _programmes = programmes);
      final highlights = await repository.getHighlights(programmes);
      if (mounted) setState(() => _highlights = highlights);
    } catch (_) {
      // The programmes section stays hidden until campaigns can be loaded.
    }
  }

  Future<void> _loadMoreRequests() async {
    try {
      final repository = Get.find<CharityRepository>();
      await repository.loadMoreDonationHistory();
      if (mounted) _loadDonations();
    } catch (_) {
      // The button stays so the donor can retry.
    }
  }

  Future<void> _donate() async {
    await Get.toNamed<dynamic>(AppRoutes.charityLocation);
    if (mounted) _loadDonations();
  }

  Future<void> _openProgramme(CharityCampaign programme) async {
    await Get.toNamed<dynamic>(AppRoutes.campaign, arguments: programme);
    if (mounted) _loadDonations();
  }

  void _select(int index) {
    setState(() => _index = index);
    _loadDonations();
    _refreshDonations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          _CustomerHome(
            active: _index == CustomerTab.home,
            donations: _donations,
            programmes: _programmes,
            highlights: _highlights,
            onDonate: _donate,
            onOpenProgramme: _openProgramme,
            onOpenRequest: _openRequest,
            onViewRequests: () => _select(CustomerTab.requests),
          ),
          _RequestsTab(
            active: _index == CustomerTab.requests,
            donations: _donations,
            onLoadMore: _hasMoreRequests ? _loadMoreRequests : null,
            onDonate: _donate,
            onOpenRequest: _openRequest,
          ),
          _ImpactTab(
            active: _index == CustomerTab.impact,
            donations: _donations,
            onDonate: _donate,
            onOpenRequest: _openRequest,
            onViewRequests: () => _select(CustomerTab.requests),
          ),
          _ProfileTab(
            active: _index == CustomerTab.profile,
            donations: _donations,
            onViewRequests: () => _select(CustomerTab.requests),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        destinations: CustomerNav.destinations,
        selectedIndex: _index,
        onSelected: _select,
        onCenterTap: _donate,
      ),
    );
  }
}

class _CustomerHeaderActions {
  static List<Widget> build() => [
    // Out of charity scope: the charity hub shortcut. Donating starts from
    // the centre action and the Home banner instead.
    // HeaderCircleButton(
    //   iconWidget: const AssetIcon(AppIcons.heartHands, size: 24),
    //   tooltip: 'Charity',
    //   onTap: onOpenCharity,
    // ),
    const NotificationBell(),
  ];
}

/// Light page that slides over the teal header with large rounded corners.
class RoundedSheet extends StatelessWidget {
  const RoundedSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(0, -1),
    child: Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: child,
    ),
  );
}

/// White title and subtitle shown in the teal header of a tab.
class _TabHeading extends StatelessWidget {
  const _TabHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13.5),
        ),
      ],
    ),
  );
}

/// Requests, meals funded and completed feedings, shared by Home and Profile.
List<Widget> _impactStats(
  List<DonationReceipt> donations, {
  VoidCallback? onViewRequests,
}) {
  final meals = donations.fold<int>(0, (sum, item) => sum + item.mealCount);
  final completed = donations.where((item) => item.status.isCompleted).length;
  return [
    StatTile(
      label: 'Requests'.tr,
      value: '${donations.length}',
      icon: Iconsax.receipt_2_copy,
      tint: AppColors.brand,
      onTap: onViewRequests,
    ),
    const SizedBox(width: 10),
    StatTile(
      label: 'Meals'.tr,
      value: meals == 0 ? '0' : '~$meals',
      icon: Icons.restaurant_rounded,
      tint: AppColors.accent,
    ),
    const SizedBox(width: 10),
    StatTile(
      label: 'Completed'.tr,
      value: '$completed',
      icon: Iconsax.tick_circle_copy,
      tint: const Color(0xFF2BB673),
      onTap: onViewRequests,
    ),
  ];
}

class _CustomerHome extends StatelessWidget {
  const _CustomerHome({
    required this.active,
    required this.donations,
    required this.programmes,
    required this.highlights,
    required this.onDonate,
    required this.onOpenProgramme,
    required this.onOpenRequest,
    required this.onViewRequests,
  });

  /// Replays the sections' entrance each time the tab is shown.
  final bool active;
  final List<DonationReceipt> donations;
  final List<CharityCampaign> programmes;
  final List<FeedingHighlight> highlights;
  final VoidCallback onDonate;
  final ValueChanged<CharityCampaign> onOpenProgramme;
  final ValueChanged<DonationReceipt> onOpenRequest;
  final VoidCallback onViewRequests;

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  static String _greeting() {
    final name = Get.find<SessionRepository>().displayName;
    final first = name?.trim().split(RegExp(r'\s+')).first ?? '';
    return first.isEmpty
        ? 'Hi there!'.tr
        : 'Hi @name!'.trParams({'name': first});
  }

  /// Where the programmes feed, e.g. "Feeding animals in Makkah & Madinah".
  String _where() {
    final cities = {for (final programme in programmes) programme.city};
    if (cities.isEmpty) return 'Feed street animals, see every meal'.tr;
    return 'Feeding animals in @cities'.trParams({
      'cities': cities.join(' ${'&'.tr} '),
    });
  }

  @override
  Widget build(BuildContext context) {
    // Out of charity scope, kept commented out further down this file:
    // My Pets, Quick Services, Reminders, Today's Offer and Vet's Daily Advice.
    return ColoredBox(
      color: AppColors.brand,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BrandHeader(
              bottomPadding: 26,
              actions: _CustomerHeaderActions.build(),
              child: HeaderGreeting(greeting: _greeting(), location: _where()),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: RoundedSheet(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  bottom: AppBottomNav.contentPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: staggered(trigger: active, [
                    Padding(
                      padding: _gutter,
                      child: _DonateBanner(onTap: onDonate),
                    ),
                    if (donations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DonationCases(
                        donations: donations.take(5).toList(growable: false),
                        onViewAll: onViewRequests,
                        onOpen: onOpenRequest,
                      ),
                    ],
                    if (programmes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: _gutter,
                        child: SectionHeader(title: 'Feeding programmes'.tr),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: 172,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: programmes.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) => _ProgrammeCard(
                            programme: programmes[index],
                            onTap: () => onOpenProgramme(programmes[index]),
                          ),
                        ),
                      ),
                    ],
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: _gutter,
                        child: SectionHeader(
                          title: 'Recent verified feedings'.tr,
                        ),
                      ),
                      const SizedBox(height: 11),
                      SizedBox(
                        height: 172,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: highlights.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) =>
                              _HighlightCard(highlight: highlights[index]),
                        ),
                      ),
                    ],
                    // Returning donors already know the steps.
                    if (donations.isEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: _gutter,
                        child: SectionHeader(title: 'How it works'.tr),
                      ),
                      const SizedBox(height: 11),
                      const Padding(padding: _gutter, child: _HowItWorks()),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feeding programme on the white swirl card used by the city and animal
/// choices: the city artwork sits faded behind the animal cut-out.
class _ProgrammeCard extends StatelessWidget {
  const _ProgrammeCard({required this.programme, required this.onTap});
  final CharityCampaign programme;
  final VoidCallback onTap;

  static String _formatCount(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final bird = programme.animalKind == AnimalKind.bird;
    final dog = programme.animalKind == AnimalKind.dog;
    final skyline = citySkyline('${programme.cityCode} ${programme.city}');
    return SizedBox(
      width: 272,
      child: SurfaceCard(
        radius: 16,
        shadow: true,
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: CardSwirlPainter()),
            if (skyline != null)
              PositionedDirectional(
                end: -28,
                top: 8,
                width: 150,
                child: Opacity(
                  opacity: .22,
                  child: Image.asset(skyline, fit: BoxFit.fitWidth),
                ),
              ),
            PositionedDirectional(
              end: bird ? -6 : 2,
              bottom: bird ? 10 : 0,
              width: bird ? 132 : (dog ? 96 : 116),
              child: Image.asset(
                animalArt(programme.animalKind),
                fit: BoxFit.contain,
                alignment: AlignmentDirectional.bottomEnd,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 0, 14),
              child: SizedBox(
                width: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      programme.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.brand,
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _MetaLine(
                      icon: const Icon(
                        Iconsax.location_copy,
                        size: 16,
                        color: Color(0xFF8E8E8E),
                      ),
                      text: programme.city,
                    ),
                    // The API doesn't send supporter counts yet.
                    if (programme.supporters > 0) ...[
                      const SizedBox(height: 4),
                      _MetaLine(
                        icon: const Icon(
                          Iconsax.people_copy,
                          size: 16,
                          color: Color(0xFF8E8E8E),
                        ),
                        text: '@count supporters'.trParams({
                          'count': _formatCount(programme.supporters),
                        }),
                      ),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: 104,
                      child: PillButton(
                        label: 'Donate'.tr,
                        height: 32,
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An anonymised approved feeding: photo, zone and meals.
class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight});
  final FeedingHighlight highlight;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: SurfaceCard(
      radius: 16,
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 96,
            width: double.infinity,
            child: LocalOrNetworkImage(
              highlight.imageUrl ?? AppAssets.charityStreet,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetaLine(
                  icon: const Icon(
                    Iconsax.location_copy,
                    size: 16,
                    color: Color(0xFF8E8E8E),
                  ),
                  text: highlight.zone,
                ),
                const SizedBox(height: 6),
                Text(
                  '@meals meals · ~@animals animals fed'.trParams({
                    'meals': '${highlight.mealCount}',
                    'animals': '${highlight.animalsFedEstimate}',
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
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

/// Three numbered steps from package to verified proof.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    ('Choose a package', 'Pick a city, an animal and a food package.'),
    (
      'A local operator feeds them',
      'A verified operator buys the food and runs the feeding round.',
    ),
    (
      'Receive verified proof',
      'Photos and impact details appear once the feeding is approved.',
    ),
  ];

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      children: [
        for (final (index, step) in _steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.$1.tr, style: _cardTitle),
                      const SizedBox(height: 2),
                      Text(step.$2.tr, style: _cardMeta),
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

/// Impact summary and the feedings whose proof has been approved.
class _ImpactTab extends StatelessWidget {
  const _ImpactTab({
    required this.active,
    required this.donations,
    required this.onDonate,
    required this.onOpenRequest,
    required this.onViewRequests,
  });

  /// Replays the sections' entrance each time the tab is shown.
  final bool active;
  final List<DonationReceipt> donations;
  final VoidCallback onDonate;
  final ValueChanged<DonationReceipt> onOpenRequest;
  final VoidCallback onViewRequests;

  @override
  Widget build(BuildContext context) {
    final verified = donations
        .where((item) => item.status.isCompleted)
        .toList(growable: false);
    return ColoredBox(
      color: AppColors.brand,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BrandHeader(
              bottomPadding: 22,
              actions: _CustomerHeaderActions.build(),
              child: _TabHeading(
                title: 'My Impact'.tr,
                subtitle: 'What your donations have achieved'.tr,
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: RoundedSheet(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  AppBottomNav.contentPadding(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: staggered(trigger: active, [
                    Row(
                      children: _impactStats(
                        donations,
                        onViewRequests: onViewRequests,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(title: 'Verified feedings'.tr),
                    const SizedBox(height: 11),
                    if (verified.isEmpty)
                      _VerifiedEmpty(
                        hasRequests: donations.isNotEmpty,
                        onDonate: onDonate,
                      )
                    else
                      for (final donation in verified) ...[
                        DonationReceiptCard(
                          receipt: donation,
                          onTap: () => onOpenRequest(donation),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo card in the charity hub style, shown until a feeding is approved.
class _VerifiedEmpty extends StatelessWidget {
  const _VerifiedEmpty({required this.hasRequests, required this.onDonate});
  final bool hasRequests;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    shadow: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          AppAssets.charityStreet,
          height: 140,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proof you can see'.tr,
                style: const TextStyle(
                  color: AppColors.brand,
                  fontSize: 19.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasRequests
                    ? 'Your requests are on their way. Photos and details appear here once a feeding is approved.'
                          .tr
                    : 'Once a feeding round is approved, its photos and details appear here.'
                          .tr,
                style: const TextStyle(fontSize: 13.5, height: 1.25),
              ),
              if (!hasRequests) ...[
                const SizedBox(height: 14),
                PillButton(
                  label: 'Feed street animals'.tr,
                  height: 34,
                  onPressed: onDonate,
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Every charity request with its status, newest first.
class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.active,
    required this.donations,
    required this.onDonate,
    required this.onOpenRequest,
    this.onLoadMore,
  });

  /// Replays the list's entrance each time the tab is shown.
  final bool active;
  final List<DonationReceipt> donations;
  final VoidCallback onDonate;
  final ValueChanged<DonationReceipt> onOpenRequest;

  /// Set while the server has older requests.
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.brand,
    child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: BrandHeader(
            bottomPadding: 22,
            actions: _CustomerHeaderActions.build(),
            child: _TabHeading(
              title: 'My Requests'.tr,
              subtitle: 'Track your feeding requests and their proof'.tr,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: RoundedSheet(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                AppBottomNav.contentPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: staggered(trigger: active, [
                  if (donations.isEmpty)
                    _EmptyRequests(onDonate: onDonate)
                  else
                    for (final donation in donations) ...[
                      DonationReceiptCard(
                        receipt: donation,
                        onTap: () => onOpenRequest(donation),
                      ),
                      const SizedBox(height: 12),
                    ],
                  if (onLoadMore != null)
                    TextButton(
                      onPressed: onLoadMore,
                      child: Text('Load more'.tr),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({required this.onDonate});
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(
      children: [
        const Icon(
          Icons.volunteer_activism_outlined,
          size: 54,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        Text(
          'No requests yet'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Your feeding requests and their progress will appear here.'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 180,
          child: PillButton(
            label: 'Donate now'.tr,
            height: 40,
            onPressed: onDonate,
          ),
        ),
      ],
    ),
  );
}

// Out of charity scope: My Pets and Quick Services on the old Home tab.
/*
/// 50 pt circle with a centred caption that may be wider than the circle.
class _AvatarItem extends StatelessWidget {
  const _AvatarItem({required this.circle, required this.label, this.onTap});
  final Widget circle;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 50,
      child: Column(
        children: [
          SizedBox.square(dimension: 50, child: circle),
          const SizedBox(height: 5),
          SizedBox(
            height: 20,
            child: OverflowBox(
              maxWidth: 120,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.pet, required this.onTap});
  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _AvatarItem(
    onTap: onTap,
    label: pet.name,
    circle: CircleAvatar(backgroundImage: AssetImage(pet.imageAsset)),
  );
}

class _AddPet extends StatelessWidget {
  const _AddPet({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _AvatarItem(
    onTap: onTap,
    label: 'Add a pet',
    circle: const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: Icon(Iconsax.add_circle_copy, color: Colors.white, size: 20),
    ),
  );
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppAssets.servicePhotoVet, 'Health & Vet'),
      (AppAssets.servicePhotoGrooming, 'Grooming & Spa'),
      (AppAssets.servicePhotoTraining, 'Training'),
      (AppAssets.servicePhotoBoarding, 'Boarding'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 130,
        crossAxisSpacing: 15,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.services, arguments: item.$2),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    item.$1,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.$2,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
*/

class _DonateBanner extends StatelessWidget {
  const _DonateBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 150),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: const DecorationImage(
          image: AssetImage(AppAssets.homeDonate),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        color: const Color(0x8C1F1F1F),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feed street animals'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a food package and a local operator feeds the animals, with photo proof.'
                  .tr,
              maxLines: 2,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(
                    fontFamily: 'Glory',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text('Donate Now'.tr),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Body text in the home cards is set in Poppins.
const _cardTitle = TextStyle(
  fontFamily: AppTheme.secondaryFontFamily,
  fontSize: 15,
  color: AppColors.textPrimary,
);
const _cardMeta = TextStyle(
  fontFamily: AppTheme.secondaryFontFamily,
  fontSize: 12,
  color: Color(0xFF8E8E8E),
);

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox.square(dimension: 18, child: Center(child: icon)),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _cardMeta,
        ),
      ),
    ],
  );
}

class _DonationCases extends StatelessWidget {
  const _DonationCases({
    required this.donations,
    required this.onViewAll,
    required this.onOpen,
  });
  final List<DonationReceipt> donations;
  final VoidCallback onViewAll;
  final ValueChanged<DonationReceipt> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SectionHeader(title: 'Your requests'.tr, onAction: onViewAll),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 110,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 21),
          scrollDirection: Axis.horizontal,
          itemCount: donations.length,
          separatorBuilder: (_, _) => const SizedBox(width: 17),
          itemBuilder: (context, index) {
            final donation = donations[index];
            final card = Container(
              width: 292,
              padding: const EdgeInsets.fromLTRB(15, 16, 15, 0),
              decoration: BoxDecoration(
                color: index.isEven
                    ? AppColors.donationCaseSurface
                    : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DonationStatusPill(
                    status: donation.status,
                    label: donation.label,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    donation.campaignTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _cardTitle,
                  ),
                  const SizedBox(height: 5),
                  _MetaLine(
                    icon: const Icon(
                      Iconsax.clock_copy,
                      size: 18,
                      color: Color(0xFF8E8E8E),
                    ),
                    text: _formatDate(donation.createdAt),
                  ),
                ],
              ),
            );
            return GestureDetector(onTap: () => onOpen(donation), child: card);
          },
        ),
      ),
    ],
  );

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}  '
      '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}

// Out of charity scope: Reminders, Today's Offer and the My Pets tab.
/*
class _Reminders extends StatelessWidget {
  const _Reminders();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i > 0) const SizedBox(width: 11),
          Container(
            constraints: const BoxConstraints(minHeight: 140),
            width: 295,
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9F2F2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Iconsax.notification_copy,
                    color: AppColors.brand,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Veterinary Dentist', style: _cardTitle),
                const SizedBox(height: 3),
                const _MetaLine(
                  icon: AssetIcon(
                    AppIcons.dogHouse,
                    size: 16,
                    color: Color(0xFF8E8E8E),
                  ),
                  text: 'Janny',
                ),
                const SizedBox(height: 5),
                const _MetaLine(
                  icon: Icon(
                    Iconsax.clock_copy,
                    size: 18,
                    color: Color(0xFF8E8E8E),
                  ),
                  text: '12/2/2022  7:00-9:00',
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _TodaysOffer extends StatelessWidget {
  const _TodaysOffer();

  static const _perkStyle = TextStyle(
    fontFamily: AppTheme.secondaryFontFamily,
    fontSize: 13.5,
    color: AppColors.textPrimary,
  );

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFFEDF3F3),
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _OfferCurvesPainter()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(21, 21, 21, 21),
          child: Column(
            children: [
              SectionHeader(
                title: "Today's Offer",
                uppercase: true,
                onAction: () => Get.toNamed(AppRoutes.services),
              ),
              const SizedBox(height: 11),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFA),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      AppAssets.homeOffer,
                      height: 153,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 10, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Pet Wellness Monthly',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ),
                              Text(
                                'SAR 149 / month',
                                style: TextStyle(
                                  color: AppColors.brand,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final perk in const [
                            '1 Vet Consultation',
                            'Vaccination reminders',
                            '10% off grooming',
                            'Priority booking',
                          ])
                            SizedBox(
                              height: 32,
                              child: Row(
                                children: [
                                  const Icon(
                                    Iconsax.tick_circle_copy,
                                    size: 19,
                                    color: Color(0xFF3BAA8A),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(perk, style: _perkStyle),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: PillButton(
                              label: 'View Plan',
                              height: 35,
                              onPressed: () => Get.toNamed(AppRoutes.services),
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Pale teal ribbons behind the offer card.
class _OfferCurvesPainter extends CustomPainter {
  const _OfferCurvesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBBE4E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    canvas.drawPath(
      Path()
        ..moveTo(-20, size.height * .55)
        ..quadraticBezierTo(
          size.width * .5,
          size.height * .38,
          size.width + 20,
          size.height * .62,
        ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MyPetsTab extends StatelessWidget {
  const _MyPetsTab({
    required this.active,
    required this.pets,
    required this.onAddPet,
    required this.onPetTap,
    required this.onOpenCharity,
  });
  final List<PetProfile> pets;
  final VoidCallback onAddPet;
  final ValueChanged<PetProfile> onPetTap;
  final VoidCallback onOpenCharity;

  /// Replays the list's entrance each time the tab is shown.
  final bool active;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      BrandHeader(actions: _CustomerHeaderActions.build(onOpenCharity)),
      Expanded(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
20,
24,
20,
AppBottomNav.contentPadding(context),
),
          children: staggered(trigger: active, [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My Pets :',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: PillButton(
                    label: 'Add a pet',
                    height: 36,
                    onPressed: onAddPet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < pets.length; index++) ...[
              _PetProfileCard(
                pet: pets[index],
                onTap: () => onPetTap(pets[index]),
              ),
              if (index != pets.length - 1) const SizedBox(height: 16),
            ],
            const SizedBox(height: 22),
            const Text(
              'Upcoming Care',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              padding: const EdgeInsets.all(14),
              onTap: () => Get.toNamed(
                AppRoutes.appointments,
                arguments: 'My Appointments',
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.brandSoft,
                    child: Icon(
                      Icons.vaccines_outlined,
                      color: AppColors.brand,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Annual vaccination',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Due 12 December',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ]),
        ),
      ),
    ],
  );
}

class _PetStat extends StatelessWidget {
  const _PetStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.brandSoft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.brand),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PetProfileCard extends StatelessWidget {
  const _PetProfileCard({required this.pet, required this.onTap});
  final PetProfile pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    child: Column(
      children: [
        Image.asset(
          pet.imageAsset,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const StatusTag(
                    label: 'Healthy',
                    foreground: Color(0xFF3BAA8A),
                    background: Color(0xFFD8EFE6),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${pet.breed} • ${pet.gender}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PetStat(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weight',
                      value: '${pet.weightKg} kg',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PetStat(
                      icon: Icons.cake_outlined,
                      label: 'Birthday',
                      value: pet.birthDate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
*/

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.active,
    required this.onViewRequests,
    this.donations = const [],
  });

  final bool active;
  final VoidCallback onViewRequests;
  final List<DonationReceipt> donations;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  Future<void> _open(String route, String label) async {
    await Get.toNamed<dynamic>(route, arguments: label);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.brand,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: BrandHeader(
              bottomPadding: 22,
              actions: _CustomerHeaderActions.build(),
              child: _TabHeading(
                title: 'My Profile'.tr,
                subtitle: 'Manage your requests, impact & settings'.tr,
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: RoundedSheet(
              child: ProfileMenu(
                active: widget.active,
                isProvider: false,
                donations: widget.donations,
                onViewRequests: widget.onViewRequests,
                onOpen: _open,
                extraItems: [
                  // Out of charity scope: the app picks the donor or operator
                  // shell from the signed-in role, so there is no mode switch.
                  // ProfileMenuItem(
                  //   label: 'Switch to Provider Mode',
                  //   subtitle: 'Accept service jobs and support animals',
                  //   icon: Icons.business_center_rounded,
                  //   iconColor: AppColors.brand,
                  //   onTap: () => Get.offAllNamed(AppRoutes.providerHome),
                  // ),
                  // The label stays English: ProfileMenu finds the sign-out
                  // item by it and shows its own translated card.
                  ProfileMenuItem(
                    label: 'Sign out',
                    icon: Icons.logout_rounded,
                    isDestructive: true,
                    onTap: ShellRouter.signOut,
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

class ProfileMenuItem {
  const ProfileMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.badge,
    this.isDestructive = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final String? badge;
  final bool isDestructive;
  final VoidCallback onTap;
}

/// Profile card plus categorized menus and metrics. Shared by customer and provider shells.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.onOpen,
    this.extraItems = const [],
    this.active = true,
    this.isProvider = false,
    this.donations = const [],
    this.onViewRequests,
  });

  final bool active;
  final bool isProvider;
  final Future<void> Function(String route, String label) onOpen;
  final List<ProfileMenuItem> extraItems;
  final List<DonationReceipt> donations;

  /// Opens the requests tab; falls back to the donation history route.
  final VoidCallback? onViewRequests;

  @override
  Widget build(BuildContext context) {
    final preferences = Get.find<SharedPreferences>();
    final session = Get.find<SessionRepository>();
    final feeder = isProvider ? Get.find<FeederRepository>().profile : null;
    final name =
        feeder?.fullName ??
        session.displayName ??
        (isProvider ? 'Operator'.tr : 'Zoovana Supporter'.tr);
    final email =
        session.email ??
        preferences.getString('profile_email') ??
        'Add your contact details'.tr;

    final viewRequests =
        onViewRequests ?? () => onOpen(AppRoutes.history, 'History');

    final tasksCompleted = feeder?.tasksCompleted ?? 0;

    final customerActivity = [
      ProfileMenuItem(
        label: 'My Requests'.tr,
        subtitle: 'Feeding requests, status & proof'.tr,
        icon: Icons.receipt_long_rounded,
        iconColor: AppColors.brand,
        badge: donations.isEmpty ? null : '${donations.length}',
        onTap: viewRequests,
      ),
      // Out of charity scope: addresses, appointments and favorites.
      // ProfileMenuItem(
      //   label: 'My Address',
      //   subtitle: 'Saved delivery and service locations',
      //   icon: Icons.location_on_rounded,
      //   iconColor: const Color(0xFF10B981),
      //   onTap: () => onOpen(AppRoutes.addresses, 'My Address'),
      // ),
      // ProfileMenuItem(
      //   label: 'My Appointment',
      //   subtitle: 'Vet checkups & clinic visits',
      //   icon: Icons.calendar_month_rounded,
      //   iconColor: const Color(0xFF6366F1),
      //   badge: appointmentCount > 0 ? '$appointmentCount Care' : null,
      //   onTap: () => onOpen(AppRoutes.appointments, 'My Appointments'),
      // ),
      // ProfileMenuItem(
      //   label: 'Favorites',
      //   subtitle: 'Saved shelters and adoptable pets',
      //   icon: Icons.favorite_rounded,
      //   iconColor: const Color(0xFFF43F5E),
      //   onTap: () => onOpen(AppRoutes.favorites, 'Favorites'),
      // ),
    ];

    final customerAccount = [
      ProfileMenuItem(
        label: 'My Profile'.tr,
        subtitle: 'Personal details and contact info'.tr,
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF0EA5E9),
        onTap: () => onOpen(AppRoutes.profileDetails, 'My Profile'),
      ),
      // Out of charity scope until payments are specified.
      // ProfileMenuItem(
      //   label: 'My Payment',
      //   subtitle: 'Payment methods and saved cards',
      //   icon: Icons.credit_card_rounded,
      //   iconColor: const Color(0xFF8B5CF6),
      //   onTap: () => onOpen(AppRoutes.payments, 'My Payments'),
      // ),
      ProfileMenuItem(
        label: 'Notifications'.tr,
        subtitle: 'Preferences & activity updates'.tr,
        icon: Icons.notifications_none_rounded,
        iconColor: const Color(0xFFF59E0B),
        onTap: () => onOpen(AppRoutes.notifications, 'Notifications'),
      ),
      ProfileMenuItem(
        label: 'Language'.tr,
        subtitle: AppLocale.names[AppLocale.code],
        icon: Icons.translate_rounded,
        iconColor: const Color(0xFF14B8A6),
        onTap: () => showLanguagePicker(context),
      ),
    ];

    final providerOperations = [
      ProfileMenuItem(
        label: 'Jobs History'.tr,
        subtitle: 'Completed assignments and tasks'.tr,
        icon: Icons.work_outline_rounded,
        iconColor: AppColors.brand,
        badge: '@count Done'.trParams({'count': '$tasksCompleted'}),
        onTap: () => onOpen(AppRoutes.providerJobs, 'Jobs'),
      ),
      ProfileMenuItem(
        label: 'Payouts'.tr,
        subtitle: 'Eligible, approved and paid fees'.tr,
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFF8B5CF6),
        onTap: () => onOpen(AppRoutes.providerPayouts, 'Payouts'),
      ),
      // Out of charity scope: ratings, and service areas that opened the
      // customer address book.
      // ProfileMenuItem(
      //   label: 'Customer Reviews',
      //   subtitle: 'Pet owner feedback and ratings',
      //   icon: Icons.star_rounded,
      //   iconColor: AppColors.star,
      //   badge: '4.9 ★',
      //   onTap: () => onOpen(AppRoutes.ratings, 'Ratings'),
      // ),
      // ProfileMenuItem(
      //   label: 'Service Areas',
      //   subtitle: 'Active zone coverage in Makkah',
      //   icon: Icons.map_outlined,
      //   iconColor: const Color(0xFF10B981),
      //   badge: 'Makkah',
      //   onTap: () => onOpen(AppRoutes.addresses, 'My Address'),
      // ),
    ];

    final providerAccount = [
      // Operator details are managed by operations; there is no edit
      // endpoint for them yet.
      // ProfileMenuItem(
      //   label: 'Provider Profile',
      //   subtitle: 'Qualifications, bio & contacts',
      //   icon: Icons.badge_outlined,
      //   iconColor: const Color(0xFF0EA5E9),
      //   onTap: () => onOpen(AppRoutes.profileDetails, 'My Profile'),
      // ),
      // Out of charity scope: this opened the customer card screen. A
      // read-only payouts list replaces it once GET /feeder/payouts is ready.
      // ProfileMenuItem(
      //   label: 'Payout Methods',
      //   subtitle: 'Bank accounts and earnings balance',
      //   icon: Icons.account_balance_wallet_outlined,
      //   iconColor: const Color(0xFF8B5CF6),
      //   onTap: () => onOpen(AppRoutes.payments, 'My Payments'),
      // ),
      ProfileMenuItem(
        label: 'Notifications'.tr,
        subtitle: 'Job alerts & order tones'.tr,
        icon: Icons.notifications_none_rounded,
        iconColor: const Color(0xFFF59E0B),
        onTap: () => onOpen(AppRoutes.notifications, 'Notifications'),
      ),
      ProfileMenuItem(
        label: 'Language'.tr,
        subtitle: AppLocale.names[AppLocale.code],
        icon: Icons.translate_rounded,
        iconColor: const Color(0xFF14B8A6),
        onTap: () => showLanguagePicker(context),
      ),
    ];

    final modeSwitchItem = extraItems.firstWhereOrNull(
      (item) => item.label.toLowerCase().contains('switch'),
    );
    final signOutItem = extraItems.firstWhereOrNull(
      (item) =>
          item.label.toLowerCase().contains('sign out') ||
          item.label == 'Sign out'.tr,
    );
    final otherExtraItems = extraItems
        .where((item) => item != modeSwitchItem && item != signOutItem)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        AppBottomNav.contentPadding(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: staggered(trigger: active, [
          _ProfileHeroCard(
            name: name,
            email: email,
            roleBadge: isProvider ? 'Verified Operator'.tr : 'Supporter'.tr,
            roleBadgeColor: isProvider
                ? const Color(0xFFE8F7EE)
                : AppColors.brandSoft,
            roleBadgeTextColor: isProvider
                ? const Color(0xFF2BB673)
                : AppColors.brand,
            roleIcon: isProvider
                ? Icons.verified_user_rounded
                : Icons.volunteer_activism_rounded,
            onTap: isProvider
                ? () {}
                : () => onOpen(AppRoutes.profileDetails, 'My Profile'),
          ),
          const SizedBox(height: 12),
          if (isProvider)
            Row(
              children: [
                StatTile(
                  label: 'Completed'.tr,
                  value: '@count Jobs'.trParams({'count': '$tasksCompleted'}),
                  icon: Iconsax.tick_circle_copy,
                  tint: const Color(0xFF2BB673),
                  onTap: () => onOpen(AppRoutes.providerJobs, 'Jobs'),
                ),
                // Out of charity scope: ratings.
                // const SizedBox(width: 10),
                // StatTile(
                //   label: 'Rating',
                //   value: '4.9 ★',
                //   icon: Icons.star_rounded,
                //   tint: AppColors.star,
                //   onTap: () => onOpen(AppRoutes.ratings, 'Ratings'),
                // ),
                const SizedBox(width: 10),
                StatTile(
                  label: 'Status'.tr,
                  value: (feeder?.isAvailable ?? false)
                      ? 'On Duty'.tr
                      : 'Off Duty'.tr,
                  icon: Icons.radio_button_checked_rounded,
                  tint: AppColors.brand,
                ),
              ],
            )
          else
            Row(
              children: _impactStats(donations, onViewRequests: viewRequests),
            ),
          const SizedBox(height: 12),
          // One menu card keeps the whole profile on screen without scrolling.
          _MenuGroup(
            items: isProvider
                ? [...providerOperations, ...providerAccount]
                : [...customerActivity, ...customerAccount],
          ),
          if (otherExtraItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MenuGroup(items: otherExtraItems),
          ],
          if (modeSwitchItem != null) ...[
            const SizedBox(height: 12),
            _ModeSwitchCard(
              title: modeSwitchItem.label,
              subtitle:
                  modeSwitchItem.subtitle ??
                  (isProvider
                      ? 'Adopt pets, book care & support animal causes'.tr
                      : 'Accept field care orders and earn rewards'.tr),
              icon: modeSwitchItem.icon,
              isProviderMode: isProvider,
              onTap: modeSwitchItem.onTap,
            ),
          ],
          if (signOutItem != null) ...[
            const SizedBox(height: 12),
            _SignOutCard(onSignOut: signOutItem.onTap),
          ],
        ]),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.roleBadge,
    required this.roleBadgeColor,
    required this.roleBadgeTextColor,
    required this.roleIcon,
    required this.onTap,
  });

  final String name;
  final String email;
  final String roleBadge;
  final Color roleBadgeColor;
  final Color roleBadgeTextColor;
  final IconData roleIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Row(
      children: [
        // There's no profile photo API, so the avatar shows initials.
        InitialsAvatar(name: name, radius: 29),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: roleBadgeColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 12, color: roleBadgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      roleBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: roleBadgeTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.surfaceSubtle,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: AppRadius.medium,
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 62,
              endIndent: 16,
              color: Color(0xFFF0F2F5),
            ),
          _MenuItemTile(item: items[i]),
        ],
      ],
    ),
  );
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({required this.item});
  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.iconColor ??
        (item.isDestructive ? AppColors.accent : AppColors.brand);
    return InkWell(
      onTap: item.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: item.isDestructive
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: item.isDestructive
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : const Color(0xFFB0B7C3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSwitchCard extends StatelessWidget {
  const _ModeSwitchCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isProviderMode = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isProviderMode;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: AppRadius.medium,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isProviderMode ? AppColors.brandSoft : AppColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'Switch'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onSignOut});
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: AppRadius.medium,
    onTap: () => _confirmSignOut(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.logout_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 8),
          Text(
            'Sign out'.tr,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    ),
  );

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign out?'.tr),
        content: Text('Are you sure you want to sign out of your account?'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              Navigator.of(context).pop();
              onSignOut();
            },
            child: Text('Sign out'.tr),
          ),
        ],
      ),
    );
  }
}
