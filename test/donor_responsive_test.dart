import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:zoovana_charity/app/core/theme/app_theme.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/data/models/donation_receipt.dart';
import 'package:zoovana_charity/app/data/models/charity_request_detail.dart';
import 'package:zoovana_charity/app/modules/home/screens/donor_tab_views.dart';
import 'package:zoovana_charity/app/modules/home/screens/donor_settings_screens.dart';
import 'package:zoovana_charity/app/shared/widgets/donor_shimmers.dart';

void main() {
  final request = DonationReceipt(
    reference: 'FR-20261107-00001',
    campaignId: 'cats',
    campaignTitle:
        'Feeding Cats of Madinah with a longer translated programme title',
    city: 'Madinah',
    packageName: '5 kg bird grain mix and additional food supplies',
    amount: '250.00',
    impact: 'Approximately 50 meals',
    createdAt: DateTime(2026, 11, 12),
    status: DonationStatus.assigned,
    statusLabel: 'Operator assigned',
  );
  tearDown(Get.reset);
  testWidgets(
    'live request failure does not claim no donations or zero impact',
    (tester) async {
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({});
      await AppBootstrap.initialize();
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DonorHomeView(
              requests: const [],
              programmes: const [],
              loadingRequests: false,
              loadingProgrammes: false,
              onRefresh: () async {},
              onOpenRequest: (_) {},
              onViewRequests: () {},
              onDonate: () {},
              error: 'Internal server error',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your charity journey starts here'), findsNothing);
      expect(find.text('Internal server error'), findsOneWidget);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DonorImpactView(
              requests: const [],
              loading: false,
              onRefresh: () async {},
              onOpen: (_) {},
              onDonate: () {},
              error: 'Internal server error',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNothing);
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('Proof you can see'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 393.0, 600.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'request list and card responsive at $width and text $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 852));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          DonationReceipt? opened;
          await tester.pumpWidget(
            GetMaterialApp(
              theme: AppTheme.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 852),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: DonorRequestsView(
                    requests: [request],
                    loading: false,
                    onRefresh: () async {},
                    onOpen: (r) => opened = r,
                    onDonate: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.text(request.campaignTitle));
          expect(opened, request);
          await tester.tap(find.byTooltip('Card view'));
          await tester.pumpAndSettle();
          expect(find.text('Show Details'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final width in [320.0, 393.0, 600.0]) {
    testWidgets('home and profile fit $width with large text', (tester) async {
      Get.testMode = true;
      SharedPreferences.setMockInitialValues({});
      await AppBootstrap.initialize();
      await tester.binding.setSurfaceSize(Size(width, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final view in <Widget>[
        DonorHomeView(
          requests: [request],
          programmes: const [],
          loadingRequests: false,
          loadingProgrammes: false,
          onRefresh: () async {},
          onOpenRequest: (_) {},
          onViewRequests: () {},
          onDonate: () {},
        ),
        DonorProfileView(onViewRequests: () {}, onRefresh: () async {}),
      ]) {
        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 852),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(body: view),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets(
    'verified feeding uses approved data and remains responsive in RTL',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final proof = DonationProof(
        media: const [],
        mealCount: 12,
        foodQuantityGrams: 3000,
        animalsFedEstimate: 7,
        approximateZone: 'An intentionally long feeding location',
        approvedAt: DateTime(2026, 11, 12),
      );
      var opened = false;
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: VerifiedFeedingCard(
                    detail: CharityRequestDetail(
                      request: request,
                      timeline: const [],
                      proof: proof,
                    ),
                    onTap: () => opened = true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('3.0 kg'), findsOneWidget);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('View Feeding Details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Feeding Details'));
      expect(opened, isTrue);
    },
  );

  testWidgets('donor settings fit a narrow screen with large text', (
    tester,
  ) async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.initialize();
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final screen in <Widget>[
      const DonorNotificationSettingsScreen(),
      const DonorLanguageScreen(),
      const DonorHelpScreen(),
      const DonorContactScreen(),
      const DonorPrivacyScreen(),
    ]) {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.5),
            ),
            child: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'all custom loading layouts fit a narrow screen with reduced motion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final shimmer in <Widget>[
        const PackageListShimmer(),
        const PackageGridShimmer(),
        const LocationListShimmer(),
        const NotificationListShimmer(),
        const RequestDetailsShimmer(),
        const SingleChildScrollView(
          child: Column(
            children: [
              RequestListShimmer(),
              HomeCaseShimmer(),
              CityGridShimmer(),
              ImpactSummaryShimmer(),
              VerifiedFeedingListShimmer(),
            ],
          ),
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 700),
                disableAnimations: true,
              ),
              child: Scaffold(body: shimmer),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
