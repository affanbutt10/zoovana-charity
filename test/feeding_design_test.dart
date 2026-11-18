import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/assets/app_assets.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/core/theme/app_theme.dart';
import 'package:zoovana_charity/app/data/models/charity_campaign.dart';
import 'package:zoovana_charity/app/data/models/charity_package.dart';
import 'package:zoovana_charity/app/data/models/charity_request_detail.dart';
import 'package:zoovana_charity/app/data/models/donation_receipt.dart';
import 'package:zoovana_charity/app/data/repositories/charity_repository.dart';
import 'package:zoovana_charity/app/modules/charity/controllers/charity_campaign_controller.dart';
import 'package:zoovana_charity/app/modules/charity/controllers/charity_checkout_controller.dart';
import 'package:zoovana_charity/app/modules/charity/models/charity_campaign_state.dart';
import 'package:zoovana_charity/app/modules/charity/models/charity_checkout_state.dart';
import 'package:zoovana_charity/app/modules/charity/screens/charity_checkout_screen.dart';
import 'package:zoovana_charity/app/modules/history/screens/request_details_screen.dart';

const campaign = CharityCampaign(
  id: 'makkah-cats',
  title: 'Feeding Cats in Makkah',
  city: 'Makkah',
  animal: 'Cats',
  animalKind: AnimalKind.cat,
  description: 'Feeding',
);
const food = CharityPackage(
  id: 'food',
  name: 'Feeding food package',
  price: '123.40',
  impact: '25 meals',
  food: 'Nutritious feeding food',
);
const secondFood = CharityPackage(
  id: 'second',
  name: 'Second food package',
  price: '98.50',
  impact: '20 meals',
  food: 'Second food description',
);
const captures = String.fromEnvironment('FEEDING_CAPTURE_DIR');

Future<void> capture(WidgetTester tester, String name) async {
  if (captures.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(captures).create(recursive: true);
    await File('$captures/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.initialize();
  });
  tearDown(Get.reset);

  test(
    'basket quantities survive filtering and removing the last item clears selection',
    () {
      final c = CharityCampaignController(
        repository: Get.find<CharityRepository>(),
      );
      c.state = const CharityCampaignState(
        isLoading: false,
        campaign: campaign,
        packages: [food, secondFood],
        selectedId: 'food',
        quantities: {'food': 1},
      );
      c.setQuantity(food, 2);
      c.setQuantity(secondFood, 1);
      c.search('Second');
      expect(c.state.visiblePackages.length, 1);
      expect(c.state.lines.length, 2);
      expect(basketTotalLabel(c.state.lines), '345.3 SAR');
      c.setQuantity(food, 0);
      c.setQuantity(secondFood, 0);
      expect(c.state.lines, isEmpty);
      expect(c.state.selected, isNull);
      c.setQuantity(food, 1000);
      expect(c.state.quantityFor('food'), 99);
    },
  );

  test('money totals use integer minor units', () {
    expect(moneyMinorUnits('0.10') + moneyMinorUnits('0.20'), 30);
    expect(
      basketTotalLabel(const [DonationLine(item: food, quantity: 2)]),
      '246.8 SAR',
    );
  });

  test(
    'unsupported basket never becomes a partial single-package request',
    () async {
      final repository = Get.find<CharityRepository>();
      final c = CharityCheckoutController(repository: repository);
      c.state = const CharityCheckoutState(
        campaign: campaign,
        package: food,
        lines: [
          DonationLine(item: food, quantity: 2),
          DonationLine(item: secondFood, quantity: 1),
        ],
      );
      c.nameController.text = 'Test Donor';
      c.emailController.text = 'test@example.com';
      c.phoneController.text = '+923001234567';
      await c.submit();
      expect(c.state!.receipt, isNull);
      expect(c.state!.error, contains('Multiple items'));
      expect(repository.getDonationHistory(), isEmpty);
      c.onClose();
    },
  );

  Future<void> setupView(
    WidgetTester tester,
    double width,
    Widget child, {
    double scale = 1,
    bool rtl = false,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (captures.isNotEmpty) {
      await tester.runAsync(() async {
        for (final entry in {
          'Glory': 'assets/fonts/Glory/static/Glory-Regular.ttf',
          'Poppins': 'assets/fonts/Poppins/Poppins-Regular.ttf',
        }.entries) {
          final loader = FontLoader(entry.key)
            ..addFont(rootBundle.load(entry.value));
          await loader.load();
        }
      });
    }
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(scale),
          ),
          child: Directionality(
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 393.0, 600.0]) {
    testWidgets('payment and review show reference sections at $width', (
      tester,
    ) async {
      final c = CharityCheckoutController(
        repository: Get.find<CharityRepository>(),
      );
      Get.put(c);
      c.state = const CharityCheckoutState(
        campaign: campaign,
        package: food,
        lines: [DonationLine(item: food, quantity: 2)],
      );
      c.nameController.text = 'Test Donor';
      c.emailController.text = 'test@example.com';
      c.phoneController.text = '+923001234567';
      await setupView(
        tester,
        width,
        const CharityCheckoutScreen(),
        scale: width == 320 ? 1.3 : 1,
      );
      expect(find.text('Choose Payment Method'), findsOneWidget);
      expect(find.text('Google Pay'), findsOneWidget);
      expect(find.text('Apple Pay'), findsOneWidget);
      expect(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .every((f) => f.readOnly),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      if (width == 393) await capture(tester, 'fixture-payment-methods');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Donate Details :'), findsOneWidget);
      expect(find.text('Feeding Items :'), findsOneWidget);
      expect(find.text('Payment Summary'), findsOneWidget);
      expect(find.text('Qty: 2'), findsOneWidget);
      expect(find.text('246.8 SAR'), findsWidgets);
      expect(tester.takeException(), isNull);
      if (width == 393) await capture(tester, 'fixture-review');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(c.state!.error, contains('Multiple items'));
      expect(c.state!.receipt, isNull);
    });
  }

  DonationReceipt request(DonationStatus status) => DonationReceipt(
    reference: 'FR-20261112-00001',
    campaignId: campaign.id,
    campaignTitle: campaign.title,
    city: campaign.city,
    packageName: food.name,
    amount: food.price,
    impact: '25 meals',
    createdAt: DateTime(2026, 11, 12, 10),
    status: status,
  );

  testWidgets(
    'pending request has every reference section and honest missing values',
    (tester) async {
      final detail = CharityRequestDetail(
        request: request(DonationStatus.assigned),
        timeline: [
          RequestEvent(
            status: DonationStatus.paid,
            at: DateTime(2026, 11, 12, 10),
          ),
          RequestEvent(
            status: DonationStatus.assigned,
            at: DateTime(2026, 11, 12, 11),
          ),
        ],
        expectedCompletionAt: DateTime(2026, 11, 13),
      );
      await setupView(
        tester,
        393,
        Scaffold(body: RequestDetailsContent(detail: detail)),
      );
      for (final section in [
        'Feeding Information',
        'Feeding Items',
        'Feeding Notes',
        'Feeding Progress',
      ]) {
        expect(find.text(section), findsOneWidget);
      }
      expect(find.text('Feeding notes are not available yet.'), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
      expect(find.text('Feeding Summary'), findsNothing);
      expect(tester.takeException(), isNull);
      await capture(tester, 'fixture-request-progress');
    },
  );

  testWidgets(
    'approved request shows summary, quantities and six-cell media gallery',
    (tester) async {
      final media = List.generate(
        7,
        (i) => ProofMedia(url: AppAssets.feedingCats, caption: 'Photo $i'),
      );
      final proof = DonationProof(
        media: media,
        mealCount: 12,
        foodQuantityGrams: 3000,
        animalsFedEstimate: 7,
        approximateZone: 'Makkah',
        approvedAt: DateTime(2026, 11, 12),
      );
      final detail = CharityRequestDetail(
        request: request(DonationStatus.completed),
        timeline: const [],
        proof: proof,
        feedingAt: DateTime(2026, 11, 12, 11),
        items: const [
          RequestFeedingItem(
            name: 'Food',
            quantity: 2,
            unitAmount: '123.40',
            currency: 'SAR',
          ),
        ],
      );
      await setupView(
        tester,
        393,
        Scaffold(body: RequestDetailsContent(detail: detail)),
      );
      for (final section in [
        'Feeding Summary',
        'Feeding Information',
        'Donation Items :',
        'Feeding Photos & Videos :',
      ]) {
        expect(find.text(section), findsOneWidget);
      }
      expect(find.text('3 kg'), findsOneWidget);
      expect(find.text('Qty: 2'), findsOneWidget);
      expect(find.text('+2 more'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture(tester, 'fixture-request-verified');
      await tester.ensureVisible(find.text('+2 more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+2 more'));
      await tester.pumpAndSettle();
      expect(find.text('6 / 7'), findsOneWidget);
    },
  );

  testWidgets(
    'request sections remain responsive at narrow width with RTL and large text',
    (tester) async {
      await setupView(
        tester,
        320,
        Scaffold(
          body: RequestDetailsContent(
            detail: CharityRequestDetail(
              request: request(DonationStatus.assigned),
              timeline: const [],
            ),
          ),
        ),
        scale: 1.3,
        rtl: true,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
