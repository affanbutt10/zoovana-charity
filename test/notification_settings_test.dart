import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/theme/app_theme.dart';
import 'package:zoovana_charity/app/modules/home/screens/donor_settings_screens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    Get.put(await SharedPreferences.getInstance());
  });
  tearDown(Get.reset);

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      final loader = FontLoader('Glory')
        ..addFont(
          rootBundle.load('assets/fonts/Glory/static/Glory-Regular.ttf'),
        );
      await loader.load();
    });
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const DonorNotificationSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'reference tiles are compact and radio indicators measure 16 px',
    (tester) async {
      await open(tester);
      await tester.binding.setSurfaceSize(const Size(360, 853));
      await tester.pumpAndSettle();
      for (final id in [
        'request_updates',
        'feeding_proof',
        'offers',
        'charity',
      ]) {
        expect(
          tester.getSize(find.byKey(ValueKey('notification_$id'))).height,
          closeTo(78, .5),
        );
      }
      await tester.binding.setSurfaceSize(const Size(393, 853));
      await tester.pumpAndSettle();
      final first = find.byKey(const ValueKey('notification_request_updates'));
      final second = find.byKey(const ValueKey('notification_feeding_proof'));
      expect(tester.getSize(first).height, closeTo(78, .5));
      expect(tester.getSize(first).width, 353);
      expect(tester.getTopLeft(second).dy - tester.getBottomLeft(first).dy, 18);
      expect(
        tester.getSize(find.byKey(const ValueKey('radio_Request updates'))),
        const Size(16, 16),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('whole tile toggles the preference and saves its state', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('notification_offers')));
    await tester.pump();
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();
    final prefs = Get.find<SharedPreferences>();
    expect(prefs.getBool('donor_notification_offers'), isTrue);
    expect(prefs.getBool('donor_notification_request_updates'), isTrue);
    expect(prefs.getBool('donor_notification_feeding_proof'), isFalse);
  });
}
