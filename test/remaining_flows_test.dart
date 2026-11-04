import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/core/assets/app_assets.dart';
import 'package:zoovana_charity/app/data/models/charity_session.dart';
import 'package:zoovana_charity/app/data/repositories/account_repository.dart';
import 'package:zoovana_charity/app/data/repositories/community_repository.dart';
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
  });

  tearDown(Get.reset);

  Future<void> pumpAtPhoneSize(WidgetTester tester, String route) async {
    await tester.binding.setSurfaceSize(const Size(393, 853));
    await tester.pumpWidget(ZoovanaCharityApp(initialRoute: route));
    await tester.pumpAndSettle();
  }

  test('account collections and favorites persist locally', () async {
    final repository = Get.find<AccountRepository>();

    await repository.addAddress(
      label: 'Work',
      address: 'Prince Sultan Road, Jeddah',
    );
    final work = repository.getAddresses().last;
    await repository.setPrimaryAddress(work.id);
    expect(
      repository.getAddresses().singleWhere((item) => item.primary).label,
      'Work',
    );

    await repository.addPaymentMethod(brand: 'VISA', lastFour: '9999');
    expect(repository.getPaymentMethods().last.lastFour, '9999');

    expect(await repository.toggleFavorite('pet:Luna'), isTrue);
    expect(repository.isFavorite('pet:Luna'), isTrue);
  });

  test('session and community activity persist locally', () async {
    final session = Get.find<SessionRepository>();
    final community = Get.find<CommunityRepository>();

    final signedIn = await session.signIn(
      email: 'donor@zoovana.demo',
      password: 'strongpass',
    );
    expect(session.hasActiveSession, isTrue);
    expect(signedIn.appMode, AppMode.donor);

    await community.submitAdoptionApplication('Luna');
    expect(community.hasAppliedFor('Luna'), isTrue);

    await session.signOut();
    expect(session.hasActiveSession, isFalse);
  });

  testWidgets('welcome screen uses the branded background', (tester) async {
    await pumpAtPhoneSize(tester, AppRoutes.auth);

    expect(find.text('Welcome to ZOOVANA'), findsOneWidget);
    // Requests need a signed-in donor, so there is no guest action.
    expect(find.text('You’re Guest donate now'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                AppAssets.splashBackground,
      ),
      findsOneWidget,
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('login validates input and starts a persisted session', (
    tester,
  ) async {
    await pumpAtPhoneSize(tester, AppRoutes.login);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Check your email and password.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter Email Address...'),
      'care@zoovana.app',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter Password...'),
      'strongpass',
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Feed street animals'), findsOneWidget);
    expect(Get.find<SessionRepository>().hasActiveSession, isTrue);
    await tester.binding.setSurfaceSize(null);
  });
}
