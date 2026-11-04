// Renders every screen at iPhone 13 Pro size (390×844 pt, 3x, notch and
// home-indicator insets) with the real fonts, and writes PNGs plus how far
// each screen scrolls. Skipped unless CAPTURE_DIR is set:
//
//   flutter test test/ui_capture --dart-define=CAPTURE_DIR=/abs/out/dir
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/data/repositories/charity_repository.dart';
import 'package:zoovana_charity/app/data/repositories/session_repository.dart';
import 'package:zoovana_charity/app/data/models/charity_package.dart';
import 'package:zoovana_charity/app/routes/app_routes.dart';
import 'package:zoovana_charity/main.dart';

const _out = String.fromEnvironment('CAPTURE_DIR');

/// Logical size; defaults to iPhone 13 Pro. The Figma frames are 393×852.
const _width = int.fromEnvironment('CAPTURE_WIDTH', defaultValue: 390);
const _height = int.fromEnvironment('CAPTURE_HEIGHT', defaultValue: 844);

Future<void> _loadFonts() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final report = StringBuffer();

  Future<void> boot(WidgetTester tester, {String? email}) async {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues({
      'zoovana_onboarding_complete_v1': true,
    });
    await AppBootstrap.initialize();
    await tester.runAsync(_loadFonts);
    if (email != null) {
      await tester.runAsync(
        () => Get.find<SessionRepository>().signIn(
          email: email,
          password: 'strongpass',
        ),
      );
    }
    tester.view
      ..physicalSize = Size(_width * 3.0, _height * 3.0)
      ..devicePixelRatio = 3
      ..padding = const FakeViewPadding(top: 141, bottom: 102)
      ..viewPadding = const FakeViewPadding(top: 141, bottom: 102);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    var scroll = 0.0;
    for (final state in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      final position = state.position;
      if (position.axis == Axis.vertical && position.maxScrollExtent > scroll) {
        scroll = position.maxScrollExtent;
      }
    }
    report.writeln('$name\tscrolls ${scroll.round()} pt');
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$_out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  Future<void> open(
    WidgetTester tester,
    String route, {
    Object? arguments,
    String? name,
  }) async {
    Get.toNamed<void>(route, arguments: arguments);
    await shot(tester, name ?? route.replaceAll('/', '_'));
  }

  tearDown(() {
    Get.reset();
  });

  tearDownAll(() {
    if (_out.isNotEmpty) File('$_out/scroll.txt').writeAsStringSync('$report');
  });

  testWidgets('signed-out screens', skip: _out.isEmpty, (tester) async {
    await boot(tester);
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.onboarding),
    );
    await shot(tester, '01_onboarding');
    Get.offAllNamed<void>(AppRoutes.auth);
    await shot(tester, '02_welcome');
    await open(tester, AppRoutes.login, name: '03_login');
    Get.back<void>();
    await open(tester, AppRoutes.signup, name: '04_signup');
    Get.back<void>();
    await open(tester, AppRoutes.recoverPassword, name: '05_recover');
  });

  testWidgets('donor screens', skip: _out.isEmpty, (tester) async {
    await boot(tester, email: 'sara@zoovana.demo');
    final repository = Get.find<CharityRepository>();
    final campaign = (await tester.runAsync(repository.getCampaigns))!.first;
    final packages = (await tester.runAsync(
      () => repository.getPackages(campaign.id),
    ))!;
    final request = (await tester.runAsync(
      () => repository.createRequest(
        campaign: campaign,
        package: packages.first,
        donor: const DonorDetails(
          fullName: 'Sara Ahmed',
          email: 'sara@zoovana.demo',
          phoneNumber: '+923001234567',
          dedication: 'In memory of my grandmother',
        ),
      ),
    ))!;
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.home),
    );
    await shot(tester, '10_home');
    for (final (index, name) in [
      (1, '11_requests'),
      (2, '12_impact'),
      (3, '13_profile'),
    ]) {
      Get.offAllNamed<void>(AppRoutes.home, arguments: index);
      await shot(tester, name);
    }
    await open(tester, AppRoutes.charityLocation, name: '14_city');
    await open(
      tester,
      AppRoutes.charityAnimal,
      arguments: [campaign],
      name: '15_animal',
    );
    await open(
      tester,
      AppRoutes.campaign,
      arguments: campaign,
      name: '16_packages',
    );
    await open(
      tester,
      AppRoutes.checkout,
      arguments: {'campaign': campaign, 'package': packages.first},
      name: '17_details',
    );
    await open(
      tester,
      AppRoutes.requestDetails,
      arguments: request,
      name: '18_request',
    );
    await open(tester, AppRoutes.notifications, name: '19_notifications');
    await open(tester, AppRoutes.profileDetails, name: '20_my_profile');
  });

  testWidgets('operator screens', skip: _out.isEmpty, (tester) async {
    await boot(tester, email: 'operator@zoovana.demo');
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.providerHome),
    );
    await shot(tester, '30_dashboard');
    Get.offAllNamed<void>(AppRoutes.providerHome, arguments: 1);
    await shot(tester, '31_jobs');
    Get.offAllNamed<void>(AppRoutes.providerHome, arguments: 2);
    await shot(tester, '32_profile');
    for (final (id, name) in [
      ('task-1001', '33_task_new'),
      ('task-1003', '34_task_buying'),
      ('task-1004', '35_task_rejected'),
      ('task-0990', '36_task_done'),
    ]) {
      await open(
        tester,
        AppRoutes.providerJobDetails,
        arguments: id,
        name: name,
      );
      Get.back<void>();
      await tester.pumpAndSettle();
    }
    await open(tester, AppRoutes.providerPayouts, name: '37_payouts');
    await open(tester, AppRoutes.operatorApply, name: '38_apply');
    await open(tester, AppRoutes.operatorStatus, name: '39_status');
    await open(tester, AppRoutes.unsupported, name: '40_unsupported');
  });
}
