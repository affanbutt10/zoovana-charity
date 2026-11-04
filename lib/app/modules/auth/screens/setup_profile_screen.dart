import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/zoovana_ui.dart';

// Out of charity scope: pet profile onboarding.
// import '../../pets/screens/pet_screens.dart';

/// First step after signup. The name is saved to the account; city, address
/// and gender stay on the device until the profile API takes them.
class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final nameController = TextEditingController();
  final userNameController = TextEditingController();
  final addressController = TextEditingController();
  String? city;
  String? gender;
  bool showErrors = false;
  bool isSaving = false;

  /// Cities with a feeding programme.
  List<String> cities = const [];

  /// The name on the account, so an unchanged name isn't re-sent.
  String? _savedName;

  @override
  void initState() {
    super.initState();
    _loadAccount();
    _loadCities();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await Get.find<SessionRepository>().donorAccount();
      _savedName = account.fullName;
      if (mounted && nameController.text.trim().isEmpty) {
        setState(() => nameController.text = account.fullName);
      }
    } catch (_) {
      // Signed out or offline: the donor types their name.
    }
  }

  Future<void> _loadCities() async {
    try {
      final programmes = await Get.find<CharityRepository>().getCampaigns();
      if (!mounted) return;
      setState(() {
        cities = {for (final programme in programmes) programme.city}.toList();
      });
    } catch (_) {
      // The city stays unpicked; the donor can retry by reopening the screen.
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    userNameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  bool get _complete =>
      nameController.text.trim().isNotEmpty &&
      userNameController.text.trim().isNotEmpty &&
      addressController.text.trim().isNotEmpty &&
      city != null &&
      gender != null;

  String? _error(TextEditingController controller) =>
      showErrors && controller.text.trim().isEmpty ? 'Required' : null;

  Future<void> _next() async {
    if (isSaving) return;
    if (!_complete) {
      setState(() => showErrors = true);
      return;
    }
    final name = nameController.text.trim();
    if (_savedName != null && name != _savedName) {
      setState(() => isSaving = true);
      try {
        await Get.find<SessionRepository>().updateDonorName(name);
      } catch (exception) {
        if (mounted) setState(() => isSaving = false);
        Get.snackbar('Profile', AppErrorMapper.map(exception).message);
        return;
      }
    }
    final preferences = Get.find<SharedPreferences>();
    await preferences.setString('profile_name', name);
    await preferences.setString(
      'profile_username',
      userNameController.text.trim(),
    );
    await preferences.setString('profile_city', city!);
    await preferences.setString(
      'profile_address',
      addressController.text.trim(),
    );
    await preferences.setString('profile_gender', gender!);
    // Out of charity scope: onboarding used to continue to the pet profile.
    // Get.toNamed(AppRoutes.addPet, arguments: AddPetScreen.onboarding);
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) => LogoHeaderScaffold(
    title: 'Setup Profile',
    actions: [PillButton(label: 'Next', onPressed: _next)],
    children: staggered([
      const SizedBox(height: 14),
      const AvatarPicker(
        child: Icon(Iconsax.user_copy, size: 52, color: Color(0xFF8E8E8E)),
      ),
      const SizedBox(height: 13),
      LabeledField(
        label: 'Full Name',
        controller: nameController,
        icon: Iconsax.user_copy,
        hint: 'Enter Full Name',
        errorText: _error(nameController),
      ),
      const SizedBox(height: 13),
      LabeledField(
        label: 'User Name',
        controller: userNameController,
        icon: Iconsax.user_copy,
        hint: 'Enter User Name',
        errorText: _error(userNameController),
      ),
      const SizedBox(height: 13),
      LabeledDropdown(
        label: 'City',
        hint: 'Select City',
        options: cities,
        value: city,
        onChanged: (value) => setState(() => city = value),
      ),
      const SizedBox(height: 13),
      LabeledField(
        label: 'Address',
        controller: addressController,
        hint: 'Enter Address',
        errorText: _error(addressController),
      ),
      const SizedBox(height: 13),
      const FieldLabel('Chose your Gender'),
      Row(
        children: [
          for (final (index, option) in const [
            ('Male', Icons.male_rounded),
            ('Female', Icons.female_rounded),
          ].indexed) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              child: RadioPill(
                label: option.$1,
                icon: option.$2,
                selected: gender == option.$1,
                onTap: () => setState(() => gender = option.$1),
              ),
            ),
          ],
        ],
      ),
      AnimatedSize(
        duration: AppMotion.medium,
        curve: AppMotion.curve,
        alignment: Alignment.topLeft,
        child: showErrors && (city == null || gender == null)
            ? const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Please choose your city and gender.',
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    ]),
  );
}

/// White pill with an icon, label and a radio indicator on the right.
class RadioPill extends StatelessWidget {
  const RadioPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: AppPressable(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          height: 46,
          padding: const EdgeInsets.only(left: 16, right: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? AppColors.brand : Colors.white,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF8E8E8E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFA3A3A3),
                  ),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.brand : const Color(0xFFD0D0D0),
                    width: 1.4,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  switchInCurve: AppMotion.curve,
                  switchOutCurve: AppMotion.curve,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: selected
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
