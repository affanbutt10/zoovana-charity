import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/assets/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../data/models/pet_profile.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/zoovana_ui.dart';

/// Two-step pet profile. Opened with [onboarding] as its argument it ends
/// on the "Your Profile is done" screen and continues to home; opened with a
/// [PetProfile] it edits that pet.
class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  static const onboarding = 'onboarding';

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  static const _types = [
    ('Cat', 'Cats', AppAssets.petTypeCat),
    ('Dog', 'Dogs', AppAssets.petTypeDog),
    ('Other', 'Others', AppAssets.logo),
    ('Bird', 'Birds', AppAssets.animalBird),
  ];

  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final microchipController = TextEditingController();
  final birthController = TextEditingController();
  int step = 0;
  String? species;
  String gender = 'Female';
  bool neutered = true;
  DateTime? birthDate;
  bool showErrors = false;
  bool done = false;
  Timer? _doneTimer;
  PetProfile? editingPet;
  late final bool fromOnboarding = Get.arguments == AddPetScreen.onboarding;

  @override
  void initState() {
    super.initState();
    if (Get.arguments is PetProfile) {
      final pet = editingPet = Get.arguments as PetProfile;
      nameController.text = pet.name;
      breedController.text = pet.breed;
      weightController.text = _number(pet.weightKg);
      if (pet.heightCm != null) heightController.text = _number(pet.heightCm!);
      microchipController.text = pet.microchipId;
      species = pet.species;
      gender = pet.gender;
      neutered = pet.neutered;
      birthController.text = pet.birthDate;
      birthDate = _parseDate(pet.birthDate);
    }
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    nameController.dispose();
    breedController.dispose();
    heightController.dispose();
    weightController.dispose();
    microchipController.dispose();
    birthController.dispose();
    super.dispose();
  }

  static String _number(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  static DateTime? _parseDate(String text) {
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final values = parts.map(int.tryParse).toList();
    if (values.contains(null)) return null;
    return DateTime(values[2]!, values[1]!, values[0]!);
  }

  static double? _measure(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(RegExp(r'[^0-9.]'), ''));

  String? get _age {
    final born = birthDate;
    if (born == null) return null;
    final now = DateTime.now();
    var years = now.year - born.year;
    if (now.month < born.month ||
        (now.month == born.month && now.day < born.day)) {
      years--;
    }
    if (years >= 1) return '$years ${years == 1 ? 'Year' : 'Years'} Old';
    final months = (now.difference(born).inDays / 30.4).floor();
    return '$months ${months == 1 ? 'Month' : 'Months'} Old';
  }

  bool get _complete =>
      nameController.text.trim().isNotEmpty &&
      breedController.text.trim().isNotEmpty &&
      _measure(heightController) != null &&
      _measure(weightController) != null &&
      birthController.text.isNotEmpty &&
      microchipController.text.trim().isNotEmpty;

  String? _error(bool missing) => showErrors && missing ? 'Required' : null;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 40),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      birthDate = picked;
      birthController.text = '${picked.day}/${picked.month}/${picked.year}';
    });
  }

  void _back() {
    if (step == 1) {
      setState(() => step = 0);
    } else {
      Get.back<void>();
    }
  }

  Future<void> _next() async {
    if (step == 0) {
      if (species == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose your pet type to continue.')),
        );
        return;
      }
      setState(() => step = 1);
      return;
    }
    if (!_complete) {
      setState(() => showErrors = true);
      return;
    }
    final pet = PetProfile(
      id: editingPet?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      species: species!,
      breed: breedController.text.trim(),
      gender: gender,
      birthDate: birthController.text,
      weightKg: _measure(weightController)!,
      heightCm: _measure(heightController),
      microchipId: microchipController.text.trim(),
      neutered: neutered,
      imageAsset:
          editingPet?.imageAsset ??
          switch (species) {
            'Cat' => AppAssets.petTypeCat,
            'Bird' => AppAssets.animalBird,
            'Other' => AppAssets.logo,
            _ => AppAssets.petTypeDog,
          },
    );
    await Get.find<PetRepository>().addPet(pet);
    if (!fromOnboarding) {
      Get.back(result: pet);
      return;
    }
    setState(() => done = true);
    _doneTimer = Timer(const Duration(milliseconds: 2500), _finish);
  }

  void _finish() {
    _doneTimer?.cancel();
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    if (done) {
      return SuccessView(title: 'Your Profile is done', onTap: _finish);
    }
    return LogoHeaderScaffold(
      title: 'Pet Profile',
      onBack: _back,
      actions: [
        PillButton(
          label: 'Back',
          style: PillButtonStyle.muted,
          onPressed: _back,
        ),
        PillButton(
          label: step == 0
              ? 'Next'
              : editingPet == null
              ? 'Start'
              : 'Save',
          onPressed: _next,
        ),
      ],
      children: [
        const SizedBox(height: 20),
        StepProgress(step: step + 1, total: 2, label: 'Pet Type'),
        // Keyed by step so each step's content cascades in when shown.
        for (final (index, child) in staggered(
          step == 0 ? _typeStep() : _detailsStep(),
        ).indexed)
          KeyedSubtree(key: ValueKey((step, index)), child: child),
      ],
    );
  }

  List<Widget> _typeStep() => [
    const SizedBox(height: 31),
    const Text(
      'What kind of pet do you have ?',
      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 8),
    const Text(
      'Choose the pet type to continue',
      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),
    const SizedBox(height: 31),
    GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        mainAxisExtent: 179,
      ),
      itemBuilder: (context, index) {
        final type = _types[index];
        return _PetTypeCard(
          label: type.$2,
          image: type.$3,
          logo: type.$1 == 'Other',
          selected: species == type.$1,
          onTap: () => setState(() => species = type.$1),
        );
      },
    ),
  ];

  List<Widget> _detailsStep() {
    Widget pair(Widget left, Widget right) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
    return [
      const SizedBox(height: 36),
      const AvatarPicker(
        child: AssetIcon(
          AppIcons.dogFace,
          size: 64,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 13),
            pair(
              LabeledField(
                label: 'Pet Name',
                controller: nameController,
                leading: const AssetIcon(
                  AppIcons.petCollar,
                  size: 20,
                  color: Color(0xFF8E8E8E),
                ),
                hint: 'Pet Name',
                errorText: _error(nameController.text.trim().isEmpty),
              ),
              LabeledDropdown(
                label: 'Species',
                leading: const AssetIcon(
                  AppIcons.petSpecies,
                  size: 20,
                  color: Color(0xFF8E8E8E),
                ),
                options: const ['Dog', 'Cat', 'Bird', 'Other'],
                value: species ?? 'Dog',
                onChanged: (value) => setState(() => species = value),
              ),
            ),
            const SizedBox(height: 13),
            pair(
              LabeledField(
                label: 'Breed',
                controller: breedController,
                leading: const AssetIcon(
                  AppIcons.petBreed,
                  size: 20,
                  color: Color(0xFF8E8E8E),
                ),
                hint: 'Beagle',
                errorText: _error(breedController.text.trim().isEmpty),
              ),
              LabeledDropdown(
                label: 'Gender',
                leading: const AssetIcon(
                  AppIcons.petGender,
                  size: 20,
                  color: Color(0xFF8E8E8E),
                ),
                options: const ['Female', 'Male'],
                value: gender,
                onChanged: (value) => setState(() => gender = value),
              ),
            ),
            const SizedBox(height: 13),
            pair(
              LabeledField(
                label: 'Height',
                controller: heightController,
                leading: const AssetIcon(
                  AppIcons.petHeight,
                  size: 20,
                  color: Color(0xFF8E8E8E),
                ),
                hint: '88 cm',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: _error(_measure(heightController) == null),
              ),
              LabeledField(
                label: 'Weight',
                controller: weightController,
                leading: const AssetIcon(
                  AppIcons.petWeight,
                  size: 20,
                  color: Color(0xFF8E8E8E),
                ),
                hint: '90 Kg',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: _error(_measure(weightController) == null),
              ),
            ),
            const SizedBox(height: 13),
            pair(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledField(
                    label: 'Date of Birth',
                    controller: birthController,
                    leading: const AssetIcon(
                      AppIcons.petCake,
                      size: 20,
                      color: Color(0xFF8E8E8E),
                    ),
                    hint: '12/2/2024',
                    readOnly: true,
                    onTap: _pickBirthDate,
                    errorText: _error(birthController.text.isEmpty),
                  ),
                  AnimatedSize(
                    duration: AppMotion.medium,
                    curve: AppMotion.curve,
                    alignment: Alignment.topLeft,
                    child: _age == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              _age!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              LabeledField(
                label: 'Microchip ID',
                controller: microchipController,
                leading: const AssetIcon(
                  AppIcons.petChip,
                  size: 20,
                  color: Color(0xFF8E8E8E),
                ),
                hint: '000000000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: _error(microchipController.text.trim().isEmpty),
              ),
            ),
            const SizedBox(height: 13),
            LabeledDropdown(
              label: 'Is your pet spayed/neutered?',
              options: const ['Yes', 'No'],
              value: neutered ? 'Yes' : 'No',
              onChanged: (value) => setState(() => neutered = value == 'Yes'),
            ),
          ],
        ),
      ),
    ];
  }
}

class _PetTypeCard extends StatelessWidget {
  const _PetTypeCard({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
    this.logo = false,
  });

  final String label;
  final String image;
  final bool selected;
  final bool logo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    label: label,
    child: AppPressable(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              height: 137,
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.brand : const Color(0xFFEDEDED),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const CustomPaint(painter: _TypeSwirlPainter()),
                    if (logo)
                      Center(child: Image.asset(image, height: 56))
                    else
                      Transform.scale(
                        scale: 1.2,
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          image,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TypeSwirlPainter extends CustomPainter {
  const _TypeSwirlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1200A7A7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .12;
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * .45,
        size.height * .2,
        size.width * 1.2,
        size.height * .8,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .3,
        -size.height * .5,
        size.width * .9,
        size.height * 1.2,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PetDetailsScreen extends StatefulWidget {
  const PetDetailsScreen({super.key});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  late PetProfile pet;

  @override
  void initState() {
    super.initState();
    pet = Get.arguments is PetProfile
        ? Get.arguments as PetProfile
        : PetProfile.river;
  }

  Future<void> _edit() async {
    final result = await Get.toNamed<dynamic>(AppRoutes.addPet, arguments: pet);
    if (result is PetProfile && mounted) setState(() => pet = result);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${pet.name}?'),
        content: const Text(
          'This removes the pet profile and its local care information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Get.find<PetRepository>().removePet(pet.id);
    Get.back(result: 'deleted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZoovanaAppBar(
        title: pet.name,
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _delete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Remove pet')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
        children: staggered([
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              children: [
                Image.asset(
                  pet.imageAsset,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text(
                        pet.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${pet.breed} • ${pet.gender}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailStat(
                              icon: Icons.cake_outlined,
                              label: 'Birthday',
                              value: pet.birthDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DetailStat(
                              icon: Icons.monitor_weight_outlined,
                              label: 'Weight',
                              value: '${pet.weightKg} kg',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Care Timeline', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const _CareTile(
            icon: Icons.vaccines_outlined,
            title: 'Annual vaccination',
            subtitle: 'Due 12 December 2026',
            color: AppColors.accent,
          ),
          const SizedBox(height: 10),
          const _CareTile(
            icon: Icons.medical_services_outlined,
            title: 'Wellness check',
            subtitle: 'Completed 18 August 2026',
            color: AppColors.brand,
          ),
          const SizedBox(height: 10),
          const _CareTile(
            icon: Icons.content_cut_rounded,
            title: 'Grooming appointment',
            subtitle: 'Due 3 November 2026',
            color: Color(0xFFFFA000),
          ),
          const SizedBox(height: 22),
          Text('Health Notes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: const Text(
              'No known allergies. Vaccinations are current. Maintain the existing feeding schedule and daily exercise routine.',
              style: TextStyle(height: 1.45),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({
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
    child: Column(
      children: [
        Icon(icon, color: AppColors.brand),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ],
    ),
  );
}

class _CareTile extends StatelessWidget {
  const _CareTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  @override
  Widget build(BuildContext context) => ListTile(
    tileColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.borderSubtle),
    ),
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: .12),
      child: Icon(icon, color: color),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
