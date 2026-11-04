import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/core/services/location_service.dart';
import 'package:zoovana_charity/app/data/models/feeder_models.dart';
import 'package:zoovana_charity/app/data/repositories/appointment_repository.dart';
import 'package:zoovana_charity/app/data/repositories/charity_repository.dart';
import 'package:zoovana_charity/app/data/repositories/community_repository.dart';
import 'package:zoovana_charity/app/data/repositories/pet_repository.dart';
import 'package:zoovana_charity/app/routes/app_routes.dart';
import 'package:zoovana_charity/app/modules/provider/controllers/operator_task_controller.dart';
import 'package:zoovana_charity/main.dart';

class _FixedLocation extends LocationService {
  @override
  Future<LocationFix> current() async =>
      const LocationFix(latitude: 21.4105, longitude: 39.8223, accuracyM: 8);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.initialize();
  });

  tearDown(Get.reset);

  Future<void> pumpAtPhoneSize(WidgetTester tester, String route) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(ZoovanaCharityApp(initialRoute: route));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shelter discovery opens verified shelter',
    (tester) async {
      await pumpAtPhoneSize(tester, AppRoutes.shelters);

      expect(find.text('All Shelters :'), findsOneWidget);
      await tester.tap(find.text('Small paw shelter').first);
      await tester.pumpAndSettle();

      expect(find.text('Shelter details'), findsOneWidget);
      expect(find.text('Small paw shelter'), findsOneWidget);
      expect(find.text('Donate to Shelter'), findsOneWidget);
      await tester.binding.setSurfaceSize(null);
    },
    // Out of charity scope: shelter donations.
    skip: true,
  );

  testWidgets(
    'shelter donation runs through items, payment, and review',
    (tester) async {
      await pumpAtPhoneSize(tester, AppRoutes.shelterHub);

      expect(find.text('Active Campaigns'), findsOneWidget);
      await tester.tap(find.text('Donate to shelter'));
      await tester.pumpAndSettle();
      expect(find.text('Select Items for donation :'), findsOneWidget);

      await tester.ensureVisible(find.text('Medications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medications'));
      await tester.pumpAndSettle();
      expect(find.text('Dogs medicine pack'), findsOneWidget);
      expect(find.text('Fabol Dog food'), findsNothing);
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Choose Payment Method'), findsOneWidget);
      expect(find.text('390SAR'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Order Items :'), findsOneWidget);
      expect(find.text('1*90'), findsOneWidget);

      await tester.tap(find.text('Donate now'));
      await tester.pumpAndSettle();
      expect(find.text('Donation successful'), findsOneWidget);
      expect(Get.find<CharityRepository>().getDonationHistory(), hasLength(1));
      await tester.binding.setSurfaceSize(null);
    },
    // Out of charity scope: shelter donations.
    skip: true,
  );

  testWidgets('operator accepts a task, buys, feeds and submits proof', (
    tester,
  ) async {
    Get.put<LocationService>(_FixedLocation());
    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.home),
    );
    await tester.pumpAndSettle();
    Get.toNamed<void>(AppRoutes.providerJobDetails, arguments: 'task-1001');
    await tester.pumpAndSettle();

    expect(find.text('Feeding zone :'), findsOneWidget);
    expect(find.textContaining('Accept in'), findsOneWidget);
    // The donor is never shown to the operator.
    expect(find.textContaining('Donor Name'), findsNothing);
    await tester.tap(find.text('Accept Task'));
    await tester.pumpAndSettle();
    expect(find.text('Task Accepted'), findsOneWidget);

    await tester.tap(find.text('View Task'));
    await tester.pumpAndSettle();
    expect(find.text('Decline'), findsOneWidget);
    await tester.tap(find.text('Start buying'));
    await tester.pumpAndSettle();
    expect(find.text('Buying food'), findsOneWidget);

    await tester.tap(find.text('Mark As bought'));
    await tester.pumpAndSettle();
    expect(find.text('On the way'), findsWidgets);
    await tester.tap(find.text('Start feeding'));
    await tester.pumpAndSettle();
    expect(find.text('Feed the animals'), findsOneWidget);

    await tester.ensureVisible(find.text('Submit proof'));
    await tester.tap(find.text('Submit proof'));
    await tester.pumpAndSettle();
    expect(
      find.text('Add at least one photo or video of the feeding.'),
      findsOneWidget,
    );

    final controller = Get.find<OperatorTaskController>();
    // The upload reads the file and waits on a timer, so it runs for real.
    await tester.runAsync(
      () => controller.addFile(
        'assets/images/charity_street.jpg',
        TaskMediaType.image,
      ),
    );
    controller.animalsController.text = '30';
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit proof'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Under review'), findsWidgets);
    expect(find.text('Submit proof'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('operator dashboard lists tasks by tab and opens the jobs tab', (
    tester,
  ) async {
    await pumpAtPhoneSize(tester, AppRoutes.providerHome);

    expect(find.text('Your Overview'), findsOneWidget);
    expect(find.textContaining('Accept in'), findsNWidgets(2));
    await tester.tap(find.text('Active (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Buying food'), findsOneWidget);
    expect(find.text('Needs changes'), findsOneWidget);

    await tester.tap(find.text('Jobs'));
    await tester.pumpAndSettle();
    expect(find.text('Jobs History :'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('rejected proof shows the reviewer reason', (tester) async {
    await pumpAtPhoneSize(tester, AppRoutes.home);
    Get.toNamed<void>(AppRoutes.providerJobDetails, arguments: 'task-1004');
    await tester.pumpAndSettle();

    expect(find.text('Please upload a clearer feeding photo.'), findsOneWidget);
    expect(find.text('Redo feeding'), findsOneWidget);
    expect(find.text('Rejected proof'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'customer books a meet-up with a shelter animal',
    (tester) async {
      await pumpAtPhoneSize(tester, AppRoutes.adoption);

      expect(find.text('Adoption Animal From Shelters'), findsOneWidget);
      await tester.tap(find.text('Show details').first);
      await tester.pumpAndSettle();
      expect(find.text('Shelter Animals :'), findsOneWidget);

      await tester.tap(find.text('Dogs (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Luna'), findsNothing);
      await tester.tap(find.text('Bites'));
      await tester.pumpAndSettle();
      expect(find.text('About Pet :'), findsOneWidget);
      expect(find.text('Golden Retriever'), findsOneWidget);

      await tester.tap(find.text('Schedule meet-up'));
      await tester.pumpAndSettle();
      expect(find.text('Select Time Available :'), findsOneWidget);
      await tester.tap(find.text('11:00 AM'));
      await tester.tap(find.text('Book now'));
      await tester.pumpAndSettle();
      expect(find.text('Thank you!'), findsOneWidget);
      expect(Get.find<CommunityRepository>().hasAppliedFor('Bites'), isTrue);
      await tester.binding.setSurfaceSize(null);
    },
    // Out of charity scope: adoption.
    skip: true,
  );

  // Out of charity scope: sign-up now goes straight to Home.
  testWidgets('signup continues into profile setup and home', skip: true, (
    tester,
  ) async {
    await pumpAtPhoneSize(tester, AppRoutes.setupProfile);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter Full Name'),
      'Ahmad Bahsas',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter User Name'),
      'ahmad',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter Address'),
      'Baghdad street',
    );
    await tester.tap(find.text('Select City'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Makkah').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Hi Ahmad!'), findsOneWidget);
    expect(find.text('Feed street animals'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'customer adds a pet and it is persisted locally',
    (tester) async {
      await pumpAtPhoneSize(tester, AppRoutes.addPet);

      expect(find.text('What kind of pet do you have ?'), findsOneWidget);
      await tester.tap(find.text('Cats'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Pet Name'),
        'Lulu',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Beagle'),
        'Domestic Shorthair',
      );
      await tester.enterText(find.widgetWithText(TextField, '88 cm'), '24');
      await tester.enterText(find.widgetWithText(TextField, '90 Kg'), '4.2');
      await tester.enterText(
        find.widgetWithText(TextField, '000000000'),
        '123456789',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(TextField, '12/2/2024'));
      await tester.tap(find.widgetWithText(TextField, '12/2/2024'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Old'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();

      final pets = Get.find<PetRepository>().getPets();
      final lulu = pets.singleWhere((pet) => pet.name == 'Lulu');
      expect(lulu.species, 'Cat');
      expect(lulu.weightKg, 4.2);
      expect(lulu.microchipId, '123456789');
      await tester.binding.setSurfaceSize(null);
    },
    // Out of charity scope: pets.
    skip: true,
  );

  testWidgets('profile menu opens the requests tab', (tester) async {
    await pumpAtPhoneSize(tester, AppRoutes.home);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Requests'));
    await tester.pumpAndSettle();
    expect(find.text('No requests yet'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'customer books a pet service and appointment is persisted',
    (tester) async {
      await pumpAtPhoneSize(tester, AppRoutes.home);

      await tester.tap(find.text('Health & Vet'));
      await tester.pumpAndSettle();
      expect(find.text('Find trusted care nearby'), findsOneWidget);

      await tester.tap(find.text('Dr. Sarah Ahmad'));
      await tester.pumpAndSettle();
      expect(find.text('What’s included'), findsOneWidget);

      await tester.tap(find.text('Book for 120 SAR'));
      await tester.pumpAndSettle();
      expect(find.text('Who is this appointment for?'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a date'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Review your booking'), findsOneWidget);

      await tester.tap(find.text('Confirm Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Booking Confirmed'), findsOneWidget);

      final appointments = Get.find<AppointmentRepository>().getAppointments();
      expect(appointments, hasLength(1));
      expect(appointments.first.petName, 'River');
      await tester.binding.setSurfaceSize(null);
    },
    // Out of charity scope: pet-care services.
    skip: true,
  );
}
