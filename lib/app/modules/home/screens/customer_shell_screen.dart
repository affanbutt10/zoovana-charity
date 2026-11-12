import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/language_picker.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import 'donor_tab_views.dart';
import '../../../core/errors/app_error_mapper.dart';

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
  bool _loadingRequests = true;
  bool _loadingProgrammes = true;
  bool _loadingMore = false;
  String? _requestsError;
  String? _programmesError;
  bool _hasMoreRequests = false;

  @override
  void initState() {
    super.initState();
    final initial = Get.arguments;
    if (initial is int && initial >= 0 && initial <= CustomerTab.profile) {
      _index = initial;
    }
    _loadDonations();
    _loadingRequests = _donations.isEmpty;
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
    if (!Get.isRegistered<CharityRepository>()) {
      if (mounted) setState(() => _loadingRequests = false);
      return;
    }
    try {
      await Get.find<CharityRepository>().refreshDonationHistory();
      if (mounted) {
        _loadDonations();
        setState(() => _requestsError = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _requestsError = AppErrorMapper.map(error).message);
      }
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshDonations(), _loadProgrammes()]);
  }

  Future<void> _openRequest(DonationReceipt request) async {
    await Get.toNamed<dynamic>(AppRoutes.requestDetails, arguments: request);
    if (mounted) _loadDonations();
  }

  Future<void> _loadProgrammes() async {
    if (!Get.isRegistered<CharityRepository>()) {
      if (mounted) setState(() => _loadingProgrammes = false);
      return;
    }
    try {
      final programmes = await Get.find<CharityRepository>().getCampaigns();
      if (mounted) {
        setState(() {
          _programmes = programmes
              .where((p) => p.isSupportedFeeding)
              .toList(growable: false);
          _programmesError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _programmesError = AppErrorMapper.map(error).message);
      }
    } finally {
      if (mounted) setState(() => _loadingProgrammes = false);
    }
  }

  Future<void> _loadMoreRequests() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final repository = Get.find<CharityRepository>();
      await repository.loadMoreDonationHistory();
      if (mounted) _loadDonations();
    } catch (error) {
      if (mounted) {
        setState(() => _requestsError = AppErrorMapper.map(error).message);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _donate() async {
    await Get.toNamed<dynamic>(AppRoutes.charityLocation);
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
          TickerMode(
            enabled: _index == CustomerTab.home,
            child: DonorHomeView(
              requests: _donations,
              programmes: _programmes,
              loadingRequests: _loadingRequests,
              loadingProgrammes: _loadingProgrammes,
              error: _requestsError ?? _programmesError,
              onRetry: _refreshAll,
              onRefresh: _refreshAll,
              onDonate: _donate,
              onOpenRequest: _openRequest,
              onViewRequests: () => _select(CustomerTab.requests),
            ),
          ),
          TickerMode(
            enabled: _index == CustomerTab.requests,
            child: DonorRequestsView(
              requests: _donations,
              loading: _loadingRequests,
              loadingMore: _loadingMore,
              error: _requestsError,
              onRefresh: _refreshDonations,
              onDonate: _donate,
              onOpen: _openRequest,
              onLoadMore: _hasMoreRequests ? _loadMoreRequests : null,
            ),
          ),
          TickerMode(
            enabled: _index == CustomerTab.impact,
            child: DonorImpactView(
              requests: _donations,
              loading: _loadingRequests,
              error: _requestsError,
              onRefresh: _refreshDonations,
              onDonate: _donate,
              onOpen: _openRequest,
            ),
          ),
          DonorProfileView(
            onViewRequests: () => _select(CustomerTab.requests),
            onRefresh: _refreshAll,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        destinations: CustomerNav.destinations,
        selectedIndex: _index,
        onSelected: _select,
        onCenterTap: _donate,
        centerIcon: Icons.add_rounded,
      ),
    );
  }
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
