import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
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

  Future<void> pumpScreen(
    WidgetTester tester,
    String route,
    String golden,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(ZoovanaCharityApp(initialRoute: route));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ZoovanaCharityApp),
      matchesGoldenFile(golden),
    );
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('customer home matches reference layout', (tester) async {
    await pumpScreen(tester, AppRoutes.home, 'goldens/customer_home.png');
  });

  testWidgets('onboarding matches reference layout', (tester) async {
    await pumpScreen(tester, AppRoutes.onboarding, 'goldens/onboarding.png');
  });

  testWidgets(
    'charity hub matches reference layout',
    (tester) async {
      await pumpScreen(tester, AppRoutes.charity, 'goldens/charity_hub.png');
    },
    // Out of charity scope: the hub route is no longer registered.
    skip: true,
  );
}
