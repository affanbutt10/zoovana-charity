import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/forms/input_rules.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../../data/models/account_models.dart';
import '../../../data/models/charity_session.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../routes/app_routes.dart';
import '../../adoption/screens/adoption_screens.dart';

/// The donor's account: name (editable), email and phone, and account
/// deletion. Loaded from and saved to the auth service.
class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  SessionRepository get session => Get.find<SessionRepository>();
  DonorAccount? account;
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    nameController.text = session.displayName ?? '';
    emailController.text = session.email ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = account == null;
      error = null;
    });
    try {
      final loaded = await session.donorAccount();
      if (!mounted) return;
      setState(() {
        account = loaded;
        if (loaded.fullName.isNotEmpty) {
          nameController.text = loaded.fullName;
        }
        emailController.text = loaded.email;
        phoneController.text = loaded.phoneNumber;
      });
    } catch (exception) {
      if (mounted) {
        setState(() => error = AppErrorMapper.map(exception).message);
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'My Profile'.tr),
      bottomNavigationBar: account == null
          ? null
          : BottomActionBar(
              children: [
                PillButton(
                  label: 'Save Changes'.tr,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : _save,
                ),
              ],
            ),
      body: AppStateView(
        isLoading: isLoading,
        error: account == null ? error : null,
        onRetry: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: staggered([
            Center(
              child: InitialsAvatar(name: nameController.text, radius: 44),
            ),
            const SizedBox(height: 20),
            LabeledField(
              label: 'Full name'.tr,
              controller: nameController,
              compact: true,
              icon: Icons.person_outline_rounded,
              hint: 'Enter your full name'.tr,
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Email'.tr,
              controller: emailController,
              compact: true,
              readOnly: true,
              required: false,
              icon: Icons.email_outlined,
            ),
            if (phoneController.text.isNotEmpty) ...[
              const SizedBox(height: 14),
              LabeledField(
                label: 'Phone number'.tr,
                controller: phoneController,
                compact: true,
                readOnly: true,
                required: false,
                icon: Icons.phone_outlined,
              ),
            ],
            const SizedBox(height: 28),
            Center(
              child: TextButton.icon(
                onPressed: _confirmDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text('Delete my account'.tr),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    if (!InputRules.name(name)) {
      Get.snackbar('My Profile'.tr, 'Enter your full name.'.tr);
      return;
    }
    setState(() => isSaving = true);
    try {
      account = await session.updateDonorName(name);
      if (!mounted) return;
      Get.back(result: true);
    } catch (exception) {
      Get.snackbar('My Profile'.tr, AppErrorMapper.map(exception).message);
    }
    if (mounted) setState(() => isSaving = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete your account?'.tr),
        content: Text(
          'You will be signed out and won’t be able to sign in with this '
                  'account again. Requests you already made are kept for our records.'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    try {
      await session.deleteDonorAccount();
      await Get.find<CharityRepository>().clearCache();
      Get.offAllNamed<void>(AppRoutes.auth);
    } catch (exception) {
      Get.snackbar('Delete account'.tr, AppErrorMapper.map(exception).message);
    }
  }
}

class AccountCollectionScreen extends StatefulWidget {
  const AccountCollectionScreen({super.key});

  @override
  State<AccountCollectionScreen> createState() =>
      _AccountCollectionScreenState();
}

class _AccountCollectionScreenState extends State<AccountCollectionScreen> {
  int selectedFilter = 0;

  AccountRepository get repository => Get.find<AccountRepository>();

  String get section =>
      Get.arguments is String ? Get.arguments as String : 'My Orders';

  @override
  Widget build(BuildContext context) => Scaffold(
    // [section] is a logic key; only its display is translated.
    appBar: ZoovanaAppBar(title: section.tr),
    floatingActionButton: section == 'My Address'
        ? FloatingActionButton.extended(
            onPressed: _addAddress,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text('Add Address'.tr),
          )
        : null,
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      children: [
        for (final (index, child) in staggered(_content(context)).indexed)
          // The first item (filter row or title) stays put; everything below
          // it cascades in again when the filter changes.
          KeyedSubtree(
            key: ValueKey(index == 0 ? null : (selectedFilter, index)),
            child: child,
          ),
      ],
    ),
  );

  List<Widget> _content(BuildContext context) {
    return switch (section) {
      'My Orders' => _orders(context),
      'My Address' => _addresses(context),
      'My Appointments' => _appointments(context),
      'My Payments' => _payments(context),
      'Favorites' => _favorites(context),
      _ => [
        _EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nothing here yet'.tr,
          body: 'Your activity will appear here.'.tr,
        ),
      ],
    };
  }

  List<Widget> _orders(BuildContext context) {
    final donations = Get.find<CharityRepository>().getDonationHistory();
    // Donations are confirmed on submission, so they all count as completed.
    final visible = selectedFilter == 1 ? const [] : donations;
    return [
      _FilterRow(
        labels: const ['All', 'Active', 'Completed'],
        selected: selectedFilter,
        onChanged: (value) => setState(() => selectedFilter = value),
      ),
      const SizedBox(height: 18),
      for (final donation in visible) ...[
        _AccountCard(
          icon: Icons.volunteer_activism_outlined,
          title: donation.campaignTitle,
          subtitle:
              '${donation.packageName} • ${donation.amount.toStringAsFixed(0)} SAR',
          badge: 'Completed'.tr,
          action: 'View history'.tr,
          onTap: () => Get.toNamed(AppRoutes.history),
        ),
        const SizedBox(height: 14),
      ],
      if (visible.isEmpty)
        _AccountCard(
          icon: Icons.volunteer_activism_outlined,
          title: 'No donation orders yet'.tr,
          subtitle:
              'Feeding and shelter donations you make will appear here.'.tr,
          badge: 'New'.tr,
          action: 'Donate now'.tr,
          onTap: () => Get.toNamed(AppRoutes.charityLocation),
        ),
    ];
  }

  List<Widget> _addresses(BuildContext context) {
    final addresses = repository.getAddresses();
    return [
      Text('Saved Addresses'.tr, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      for (var index = 0; index < addresses.length; index++) ...[
        _AddressCard(
          address: addresses[index],
          onSetPrimary: () async {
            await repository.setPrimaryAddress(addresses[index].id);
            if (mounted) setState(() {});
          },
          onDelete: () async {
            await repository.removeAddress(addresses[index].id);
            if (mounted) setState(() {});
          },
        ),
        if (index != addresses.length - 1) const SizedBox(height: 14),
      ],
      if (addresses.isEmpty)
        _EmptyState(
          icon: Icons.location_off_outlined,
          title: 'No saved addresses'.tr,
          body: 'Add an address to make checkout faster.'.tr,
        ),
    ];
  }

  List<Widget> _appointments(BuildContext context) {
    final saved = Get.find<AppointmentRepository>().getAppointments();
    return [
      _FilterRow(
        labels: const ['Upcoming', 'Completed', 'Canceled'],
        selected: selectedFilter,
        onChanged: (value) => setState(() => selectedFilter = value),
      ),
      const SizedBox(height: 18),
      for (var index = 0; index < saved.length; index++) ...[
        _AppointmentCard(
          icon: Icons.medical_services_outlined,
          title: saved[index].service,
          pet: saved[index].petName,
          date: '${saved[index].date} • ${saved[index].time}',
        ),
        const SizedBox(height: 14),
      ],
      const _AppointmentCard(
        icon: Icons.medical_services_outlined,
        title: 'Veterinary Dentist',
        pet: 'River',
        date: '12 December • 7:00–9:00 PM',
      ),
      const SizedBox(height: 14),
      const _AppointmentCard(
        icon: Icons.content_cut_rounded,
        title: 'Grooming & Spa',
        pet: 'River',
        date: '3 November • 4:30 PM',
      ),
    ];
  }

  List<Widget> _payments(BuildContext context) {
    final methods = repository.getPaymentMethods();
    return [
      Text('Payment Methods'.tr, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      for (var index = 0; index < methods.length; index++) ...[
        _PaymentCard(
          method: methods[index],
          onSetPrimary: () async {
            await repository.setPrimaryPaymentMethod(methods[index].id);
            if (mounted) setState(() {});
          },
          onDelete: () async {
            await repository.removePaymentMethod(methods[index].id);
            if (mounted) setState(() {});
          },
        ),
        if (index != methods.length - 1) const SizedBox(height: 12),
      ],
      const SizedBox(height: 22),
      OutlinedButton.icon(
        onPressed: _addPaymentMethod,
        icon: const Icon(Icons.add_card_outlined),
        label: Text('Add Payment Method'.tr),
      ),
    ];
  }

  List<Widget> _favorites(BuildContext context) {
    final favorites = repository.getFavorites();
    final showShelter =
        favorites.contains('shelter:small-paw') && selectedFilter != 2;
    final pets = selectedFilter == 1
        ? const <AdoptionPet>[]
        : adoptionPets
              .where((pet) => favorites.contains(pet.favoriteId))
              .toList();
    return [
      _FilterRow(
        labels: const ['All', 'Shelters', 'Pets'],
        selected: selectedFilter,
        onChanged: (value) => setState(() => selectedFilter = value),
      ),
      const SizedBox(height: 18),
      if (showShelter) ...[
        _FavoriteCard(
          image: AppAssets.shelterPuppy,
          title: 'Small paw shelter',
          subtitle: 'Green Valley Rescue • 3.5 km away',
          onTap: () => Get.toNamed(AppRoutes.shelterDetails),
        ),
        const SizedBox(height: 14),
      ],
      for (final pet in pets) ...[
        _FavoriteCard(
          image: pet.image,
          title: pet.name,
          subtitle: '${pet.breed} • ${pet.gender}',
          onTap: () => Get.toNamed(AppRoutes.adoptionDetails, arguments: pet),
        ),
        const SizedBox(height: 14),
      ],
      if (!showShelter && pets.isEmpty)
        _EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'No favorites yet'.tr,
          body: 'Tap the heart on shelters or adoptable pets to save them.'.tr,
        ),
    ];
  }

  void _addAddress() {
    final labelController = TextEditingController();
    final addressController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Address'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: 'Label'.tr,
                hintText: 'e.g. Work'.tr,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Address'.tr,
                hintText: 'Street, building, district'.tr,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final label = labelController.text.trim();
                  final address = addressController.text.trim();
                  if (label.isEmpty || address.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Enter a label and complete address.'.tr),
                      ),
                    );
                    return;
                  }
                  await repository.addAddress(label: label, address: address);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text('Save Address'.tr),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      labelController.dispose();
      addressController.dispose();
    });
  }

  void _addPaymentMethod() {
    final cardController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Payment Method'.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cardController,
              keyboardType: TextInputType.number,
              maxLength: 19,
              decoration: InputDecoration(
                labelText: 'Card number'.tr,
                hintText: '0000 0000 0000 0000',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final digits = cardController.text.replaceAll(
                    RegExp(r'\D'),
                    '',
                  );
                  if (digits.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Enter a valid card number.'.tr)),
                    );
                    return;
                  }
                  await repository.addPaymentMethod(
                    brand: digits.startsWith('4') ? 'VISA' : 'CARD',
                    lastFour: digits.substring(digits.length - 4),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text('Save Payment Method'.tr),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(cardController.dispose);
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < labels.length; index++)
        Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              end: index < labels.length - 1 ? 8 : 0,
            ),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(labels[index].tr, textAlign: TextAlign.center),
              ),
              selected: index == selected,
              onSelected: (_) => onChanged(index),
            ),
          ),
        ),
    ],
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.brandSoft,
              child: Icon(icon, color: AppColors.brand),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            Chip(label: Text(badge)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: onTap, child: Text(action)),
        ),
      ],
    ),
  );
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onSetPrimary,
    required this.onDelete,
  });
  final SavedAddress address;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.medium,
    curve: AppMotion.curve,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: address.primary ? AppColors.brand : AppColors.borderSubtle,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          backgroundColor: AppColors.brandSoft,
          child: Icon(Icons.location_on_outlined, color: AppColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    address.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (address.primary)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: Chip(label: Text('Primary'.tr)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(address.address, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'primary') onSetPrimary();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (!address.primary)
              PopupMenuItem(value: 'primary', child: Text('Set as primary'.tr)),
            PopupMenuItem(value: 'delete', child: Text('Delete'.tr)),
          ],
        ),
      ],
    ),
  );
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.icon,
    required this.title,
    required this.pet,
    required this.date,
  });
  final IconData icon;
  final String title;
  final String pet;
  final String date;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.brandSoft,
          child: Icon(icon, color: AppColors.brand),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                '$pet • $date',
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.method,
    required this.onSetPrimary,
    required this.onDelete,
  });
  final SavedPaymentMethod method;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.medium,
    curve: AppMotion.curve,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: method.primary
            ? const [AppColors.brand, AppColors.brandDeep]
            : const [Color(0xFF333A47), Color(0xFF171B23)],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Text(
          method.brand,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const Spacer(),
        Text(
          '•••• ${method.lastFour}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (method.primary)
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 10),
            child: Icon(Icons.check_circle_rounded, color: Colors.white),
          ),
        PopupMenuButton<String>(
          iconColor: Colors.white,
          onSelected: (value) {
            if (value == 'primary') onSetPrimary();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (!method.primary)
              PopupMenuItem(value: 'primary', child: Text('Set as primary'.tr)),
            PopupMenuItem(value: 'delete', child: Text('Delete'.tr)),
          ],
        ),
      ],
    ),
  );
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppPressable(
    child: ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Image.asset(image, width: 68, height: 68, fit: BoxFit.cover),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.favorite_rounded, color: AppColors.accent),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 120),
    child: Column(
      children: [
        Icon(icon, size: 64, color: AppColors.brand),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 7),
        Text(body, textAlign: TextAlign.center),
      ],
    ),
  );
}
