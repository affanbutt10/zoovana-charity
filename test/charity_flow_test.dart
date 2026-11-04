import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/data/repositories/session_repository.dart';
import 'package:zoovana_charity/app/routes/app_routes.dart';
import 'package:zoovana_charity/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.initialize();
    await Get.find<SessionRepository>().signIn(
      email: 'sara@zoovana.demo',
      password: 'strongpass',
    );
  });

  tearDown(Get.reset);

  testWidgets('donor creates a street-animal feeding request', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.charityLocation),
    );
    await tester.pumpAndSettle();

    expect(find.text('Where do you want to donate ?'), findsOneWidget);

    await tester.tap(find.text('city of makkah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feed Cats'));
    await tester.pumpAndSettle();

    expect(find.text('Food Packages'), findsOneWidget);
    expect(find.text('Popular'), findsOneWidget);
    await tester.tap(find.text('Dental Chews'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Donor Details'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter your full name'),
      'Sara Ahmed',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '+92 3xx xxx xxxx'),
      '+923001234567',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Donate Details'), findsOneWidget);
    expect(find.text('Dental Chews'), findsOneWidget);
    expect(find.text('98.5 SAR'), findsNWidgets(2));
    await tester.tap(find.text('Confirm request'));
    await tester.pumpAndSettle();

    expect(find.text('Request created'), findsOneWidget);
    await tester.tap(find.text('View my requests'));
    await tester.pumpAndSettle();

    expect(find.text('My Requests'), findsOneWidget);
    expect(find.text('Finding an operator'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
