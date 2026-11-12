import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/core/assets/app_assets.dart';
import 'package:zoovana_charity/app/data/models/charity_campaign.dart';
import 'package:zoovana_charity/app/routes/app_routes.dart';
import 'package:zoovana_charity/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.initialize();
  });

  tearDown(Get.reset);

  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.onboarding),
    );
    await tester.pumpAndSettle();
  }

  test('donor feeding options exclude dogs, other animals and other cities', () {
    CharityCampaign programme(String city, AnimalKind kind) => CharityCampaign(
      id: 'test', title: 'test', city: city, cityCode: city.toUpperCase(),
      animal: kind.name, animalKind: kind, description: '',
    );
    expect(programme('Makkah', AnimalKind.cat).isSupportedFeeding, isTrue);
    expect(programme('Madinah', AnimalKind.bird).isSupportedFeeding, isTrue);
    expect(programme('Makkah', AnimalKind.dog).isSupportedFeeding, isFalse);
    expect(programme('Madinah', AnimalKind.other).isSupportedFeeding, isFalse);
    expect(programme('Other city', AnimalKind.cat).isSupportedFeeding, isFalse);
  });

  testWidgets('continue swaps the copy for the next page', (tester) async {
    await pumpOnboarding(tester);
    expect(find.text('Feed Cats & Birds in Makkah'), findsOneWidget);
    expect(find.image(const AssetImage(AppAssets.feedingMakkah)), findsWidgets);

    await tester.tap(find.text('Continue'));
    // Start paging, pass the page's midpoint, then a frame into the copy
    // transition.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));
    // Mid-transition both titles are on screen.
    expect(find.text('Feed Cats & Birds in Makkah'), findsOneWidget);
    expect(find.text('Support Feeding in Madinah'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Feed Cats & Birds in Makkah'), findsNothing);
    expect(find.text('Support Feeding in Madinah'), findsOneWidget);
  });

  testWidgets('swiping the panel pages through to the last page', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    // The panel sits outside the PageView, so this exercises the forwarding.
    for (var i = 0; i < 2; i++) {
      await tester.fling(find.text('Skip'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
    }

    expect(find.text('See Your Feeding Impact'), findsOneWidget);
    expect(find.image(const AssetImage(AppAssets.feedingBirds)), findsWidgets);
    expect(find.text('Start now'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });
}
