import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/assets/app_assets.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/data/repositories/session_repository.dart';
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

  Finder zoovanaLogo() => find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == AppAssets.logo,
  );

  Finder splashBackground() => find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == AppAssets.splashBackground,
  );

  testWidgets('splash displays the Zoovana logo and opens onboarding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(const ZoovanaCharityApp());
    await tester.pump();

    expect(zoovanaLogo(), findsOneWidget);
    expect(splashBackground(), findsOneWidget);
    expect(find.text('Feed cats & birds, see every meal'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();
    expect(find.text('Feed Cats & Birds in Makkah'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('splash resumes an existing session', (tester) async {
    await Get.find<SharedPreferences>().setBool(
      'zoovana_onboarding_complete_v1',
      true,
    );
    // The seed login waits on a real timer.
    await tester.runAsync(
      () => Get.find<SessionRepository>().signIn(
        email: 'donor@zoovana.demo',
        password: 'strongpass',
      ),
    );

    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(const ZoovanaCharityApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Feed street animals'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('splash opens the operator shell for an approved operator', (
    tester,
  ) async {
    await Get.find<SharedPreferences>().setBool(
      'zoovana_onboarding_complete_v1',
      true,
    );
    // The seed login waits on a real timer.
    await tester.runAsync(
      () => Get.find<SessionRepository>().signIn(
        email: 'operator@zoovana.demo',
        password: 'strongpass',
      ),
    );

    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(const ZoovanaCharityApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Your Overview'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('splash sends a signed-out user to the auth screens', (
    tester,
  ) async {
    await Get.find<SharedPreferences>().setBool(
      'zoovana_onboarding_complete_v1',
      true,
    );

    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(const ZoovanaCharityApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to ZOOVANA'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
