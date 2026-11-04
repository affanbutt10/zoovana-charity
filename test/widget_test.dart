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

  tearDown(() {
    Get.reset();
  });

  testWidgets('home displays the donate entry and feeding programmes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.home),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hi there!'), findsOneWidget);
    expect(find.text('Feed street animals'), findsOneWidget);
    expect(find.text('Feeding programmes'), findsOneWidget);
    expect(find.text('Feed Cats in Makkah'), findsOneWidget);
  });
}
