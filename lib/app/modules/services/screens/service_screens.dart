import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/pet_appointment.dart';
import '../../../data/models/pet_profile.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../routes/app_routes.dart';

class PetServiceProvider {
  const PetServiceProvider({
    required this.name,
    required this.service,
    required this.specialty,
    required this.image,
    required this.price,
    required this.rating,
    required this.distance,
  });

  final String name;
  final String service;
  final String specialty;
  final String image;
  final double price;
  final double rating;
  final String distance;
}

List<PetServiceProvider> providersFor(String service) {
  final image = switch (service) {
    'Grooming & Spa' => AppAssets.serviceGrooming,
    'Training' => AppAssets.serviceTraining,
    'Boarding' => AppAssets.serviceBoarding,
    _ => AppAssets.serviceVet,
  };
  final specialty = switch (service) {
    'Grooming & Spa' => 'Full groom, bath, nail care',
    'Training' => 'Positive behavior and obedience',
    'Boarding' => 'Safe day care and overnight stay',
    _ => 'General wellness and dentistry',
  };
  return [
    PetServiceProvider(
      name: service == 'Health & Vet' ? 'Dr. Sarah Ahmad' : 'Happy Paws Center',
      service: service,
      specialty: specialty,
      image: image,
      price: service == 'Boarding' ? 180 : 120,
      rating: 4.9,
      distance: '1.8 km',
    ),
    PetServiceProvider(
      name: service == 'Health & Vet'
          ? 'Zoovana Care Clinic'
          : 'Pet Wellness Studio',
      service: service,
      specialty: specialty,
      image: image,
      price: service == 'Training' ? 150 : 95,
      rating: 4.8,
      distance: '3.2 km',
    ),
    PetServiceProvider(
      name: 'Green Valley Pet Care',
      service: service,
      specialty: specialty,
      image: image,
      price: 135,
      rating: 4.7,
      distance: '4.6 km',
    ),
  ];
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late String selectedService;
  String query = '';

  @override
  void initState() {
    super.initState();
    selectedService = Get.arguments is String
        ? Get.arguments as String
        : 'Health & Vet';
  }

  @override
  Widget build(BuildContext context) {
    final providers = providersFor(selectedService).where((provider) {
      final normalized = query.trim().toLowerCase();
      return normalized.isEmpty ||
          provider.name.toLowerCase().contains(normalized) ||
          provider.specialty.toLowerCase().contains(normalized);
    }).toList();
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Pet Services'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        children: staggered([
          Text(
            'Find trusted care nearby',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'Book verified professionals for every stage of your pet’s care.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search services or providers...',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.brand),
              suffixIcon: Icon(Icons.tune_rounded, color: AppColors.brand),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final service in const [
                  'Health & Vet',
                  'Grooming & Spa',
                  'Training',
                  'Boarding',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(service),
                      selected: selectedService == service,
                      onSelected: (_) =>
                          setState(() => selectedService = service),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedService,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              AppAnimatedLabel(
                '${providers.length} nearby',
                value: providers.length,
                style: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.curve,
            switchOutCurve: AppMotion.curve,
            layoutBuilder: pinnedSwitcherLayout,
            child: Column(
              key: ValueKey(selectedService),
              children: [
                for (var index = 0; index < providers.length; index++) ...[
                  _ProviderCard(provider: providers[index]),
                  if (index != providers.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});
  final PetServiceProvider provider;

  @override
  Widget build(BuildContext context) => AppPressable(
    child: InkWell(
      onTap: () => Get.toNamed(AppRoutes.serviceDetails, arguments: provider),
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Image.asset(
              provider.image,
              height: 155,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF26C97A),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    provider.specialty,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '⭐ ${provider.rating}  •  ⌖ ${provider.distance}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'From ${provider.price.toStringAsFixed(0)} SAR',
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w800,
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
    ),
  );
}

class ServiceDetailsScreen extends StatelessWidget {
  const ServiceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Get.arguments is PetServiceProvider
        ? Get.arguments as PetServiceProvider
        : providersFor('Health & Vet').first;
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Service Details'),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: () =>
              Get.toNamed(AppRoutes.bookService, arguments: provider),
          child: Text('Book for ${provider.price.toStringAsFixed(0)} SAR'),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: Colors.white,
            child: Image.asset(
              provider.image,
              width: double.infinity,
              height: 260,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: staggered([
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        provider.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF26C97A),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  provider.specialty,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '⭐ ${provider.rating}  (240 reviews)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('⌖ ${provider.distance}'),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'About this service',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 9),
                Text(
                  'A complete ${provider.service.toLowerCase()} appointment tailored to your pet. Every Zoovana provider is identity-verified and reviewed for quality, safety, and animal-friendly practice.',
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 22),
                Text(
                  'What’s included',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const _IncludedRow(text: 'Initial needs assessment'),
                const _IncludedRow(text: 'One-to-one professional care'),
                const _IncludedRow(text: 'Digital care notes after the visit'),
                const _IncludedRow(
                  text: 'Follow-up support in the Zoovana app',
                ),
                const SizedBox(height: 22),
                Text(
                  'Next availability',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Today • 4:30 PM')),
                    Chip(label: Text('Tomorrow • 9:00 AM')),
                    Chip(label: Text('Tomorrow • 1:30 PM')),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.brand),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Zoovana booking protection includes verified providers and secure payments.',
                        ),
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
}

class BookServiceScreen extends StatefulWidget {
  const BookServiceScreen({super.key});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  int step = 0;
  late final PetServiceProvider provider;
  late final List<PetProfile> pets;
  late PetProfile selectedPet;
  String selectedDate = 'Tomorrow';
  String selectedTime = '9:00 AM';

  @override
  void initState() {
    super.initState();
    provider = Get.arguments is PetServiceProvider
        ? Get.arguments as PetServiceProvider
        : providersFor('Health & Vet').first;
    pets = Get.find<PetRepository>().getPets();
    selectedPet = pets.first;
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Select Pet', 'Date and Time', 'Review'];
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Book Service'),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Row(
          children: [
            if (step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => step--),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton(
                onPressed: step == 2 ? _confirm : () => setState(() => step++),
                child: Text(step == 2 ? 'Confirm Booking' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: staggered([
          Row(
            children: [
              AppAnimatedLabel(
                'STEP ${step + 1} OF 3',
                value: step,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '• ${labels[step]}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          TweenAnimationBuilder<double>(
            tween: Tween(end: (step + 1) / 3),
            duration: AppMotion.medium,
            curve: AppMotion.curve,
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 24),
          _BookingProvider(provider: provider),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.curve,
            switchOutCurve: AppMotion.curve,
            layoutBuilder: pinnedSwitcherLayout,
            child: KeyedSubtree(
              key: ValueKey(step),
              child: switch (step) {
                0 => _PetSelection(
                  pets: pets,
                  selected: selectedPet,
                  onChanged: (pet) => setState(() => selectedPet = pet),
                ),
                1 => _ScheduleSelection(
                  date: selectedDate,
                  time: selectedTime,
                  onDateChanged: (value) =>
                      setState(() => selectedDate = value),
                  onTimeChanged: (value) =>
                      setState(() => selectedTime = value),
                ),
                _ => _BookingReview(
                  provider: provider,
                  pet: selectedPet,
                  date: selectedDate,
                  time: selectedTime,
                ),
              },
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirm() async {
    final appointment = PetAppointment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      service: provider.service,
      provider: provider.name,
      petName: selectedPet.name,
      date: selectedDate,
      time: selectedTime,
      price: provider.price,
      status: 'Confirmed',
    );
    await Get.find<AppointmentRepository>().addAppointment(appointment);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.brand,
          size: 64,
        ),
        title: const Text('Booking Confirmed'),
        content: Text(
          '${selectedPet.name} is booked with ${provider.name} on $selectedDate at $selectedTime.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Get.offAllNamed(AppRoutes.home),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}

class _IncludedRow extends StatelessWidget {
  const _IncludedRow({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF26C97A),
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _BookingProvider extends StatelessWidget {
  const _BookingProvider({required this.provider});
  final PetServiceProvider provider;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Row(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(provider.image, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.service,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(provider.name),
              const SizedBox(height: 4),
              Text(
                '${provider.price.toStringAsFixed(0)} SAR',
                style: const TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PetSelection extends StatelessWidget {
  const _PetSelection({
    required this.pets,
    required this.selected,
    required this.onChanged,
  });
  final List<PetProfile> pets;
  final PetProfile selected;
  final ValueChanged<PetProfile> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Who is this appointment for?',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 14),
      for (final pet in pets)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppPressable(
            child: InkWell(
              onTap: () => onChanged(pet),
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.curve,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected.id == pet.id
                      ? AppColors.brandSoft
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected.id == pet.id
                        ? AppColors.brand
                        : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage(pet.imageAsset),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            pet.breed,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected.id == pet.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: AppColors.brand,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _ScheduleSelection extends StatelessWidget {
  const _ScheduleSelection({
    required this.date,
    required this.time,
    required this.onDateChanged,
    required this.onTimeChanged,
  });
  final String date;
  final String time;
  final ValueChanged<String> onDateChanged;
  final ValueChanged<String> onTimeChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Choose a date', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final value in const [
            'Today',
            'Tomorrow',
            'Thu, 22 Oct',
            'Fri, 23 Oct',
          ])
            ChoiceChip(
              label: Text(value),
              selected: date == value,
              onSelected: (_) => onDateChanged(value),
            ),
        ],
      ),
      const SizedBox(height: 24),
      Text('Available times', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: [
          for (final value in const [
            '9:00 AM',
            '10:30 AM',
            '1:30 PM',
            '3:00 PM',
            '4:30 PM',
            '6:00 PM',
          ])
            ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(value, textAlign: TextAlign.center),
              ),
              selected: time == value,
              onSelected: (_) => onTimeChanged(value),
            ),
        ],
      ),
      const SizedBox(height: 20),
      const TextField(
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Notes for the provider',
          hintText: 'Anything the provider should know?',
        ),
      ),
    ],
  );
}

class _BookingReview extends StatelessWidget {
  const _BookingReview({
    required this.provider,
    required this.pet,
    required this.date,
    required this.time,
  });
  final PetServiceProvider provider;
  final PetProfile pet;
  final String date;
  final String time;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Review your booking',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 14),
      _ReviewLine(
        icon: Icons.pets_outlined,
        label: 'Pet',
        value: '${pet.name} • ${pet.breed}',
      ),
      _ReviewLine(
        icon: Icons.medical_services_outlined,
        label: 'Service',
        value: provider.service,
      ),
      _ReviewLine(
        icon: Icons.person_outline_rounded,
        label: 'Provider',
        value: provider.name,
      ),
      _ReviewLine(
        icon: Icons.calendar_month_outlined,
        label: 'Schedule',
        value: '$date • $time',
      ),
      _ReviewLine(
        icon: Icons.payments_outlined,
        label: 'Total',
        value: '${provider.price.toStringAsFixed(0)} SAR',
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.brandSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'You can reschedule or cancel from My Appointments. Provider cancellation rules may apply.',
          style: TextStyle(height: 1.4),
        ),
      ),
    ],
  );
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSubtle),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    ),
  );
}
