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

  testWidgets('all app routes render at the reference phone size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.home),
    );
    await tester.pumpAndSettle();

    const routes = <String>[
      AppRoutes.onboarding,
      AppRoutes.auth,
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.recoverPassword,
      AppRoutes.notifications,
      // Out of charity scope and no longer registered:
      // AppRoutes.charity,
      // AppRoutes.charitySupport,
      AppRoutes.charityLocation,
      AppRoutes.charityAnimal,
      AppRoutes.campaign,
      AppRoutes.checkout,
      AppRoutes.history,
      AppRoutes.requestDetails,
      // AppRoutes.shelterHub,
      // AppRoutes.shelters,
      // AppRoutes.shelterCampaigns,
      // AppRoutes.shelterDetails,
      // AppRoutes.shelterInfo,
      // AppRoutes.ratings,
      AppRoutes.unsupported,
      AppRoutes.operatorApply,
      AppRoutes.operatorStatus,
      AppRoutes.providerHome,
      AppRoutes.providerJobs,
      AppRoutes.providerJobDetails,
      AppRoutes.providerPayouts,
      // AppRoutes.adoption,
      // AppRoutes.adoptionDetails,
      // AppRoutes.adoptionApply,
      // AppRoutes.addPet,
      // AppRoutes.petDetails,
      AppRoutes.profileDetails,
      AppRoutes.orders,
      // AppRoutes.addresses,
      // AppRoutes.appointments,
      // AppRoutes.payments,
      // AppRoutes.favorites,
      // AppRoutes.services,
      // AppRoutes.serviceDetails,
      // AppRoutes.bookService,
    ];

    for (final route in routes) {
      Get.offAllNamed<void>(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Route failed: $route');
    }

    await tester.binding.setSurfaceSize(null);
  });
}
