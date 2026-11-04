import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/bootstrap/app_bootstrap.dart';
import 'package:zoovana_charity/app/data/models/donation_receipt.dart';
import 'package:zoovana_charity/app/routes/app_routes.dart';
import 'package:zoovana_charity/main.dart';

DonationReceipt _request({required Duration age}) => DonationReceipt(
  reference: 'ZCV-1001',
  campaignId: 'makkah-cats',
  campaignTitle: 'Feeding Makkah Cats',
  city: 'Makkah',
  packageName: 'Mango Sunrise',
  amount: '123.40',
  impact: 'Approximately 25 meals',
  createdAt: DateTime.now().subtract(age),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDetails(WidgetTester tester, DonationReceipt request) async {
    Get.testMode = true;
    Get.reset();
    SharedPreferences.setMockInitialValues({
      'charity_donation_history_v1': jsonEncode([request.toJson()]),
    });
    await AppBootstrap.initialize();
    await tester.binding.setSurfaceSize(const Size(393, 1600));
    await tester.pumpWidget(
      const ZoovanaCharityApp(initialRoute: AppRoutes.home),
    );
    await tester.pumpAndSettle();
    Get.toNamed<void>(AppRoutes.requestDetails, arguments: request);
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('in-progress request shows completed steps and photos', (
    tester,
  ) async {
    // Two demo stages reached: operator assigned and food purchased.
    await pumpDetails(tester, _request(age: const Duration(seconds: 70)));

    expect(find.text('Request details'), findsOneWidget);
    expect(find.text('Operator assigned'), findsOneWidget);
    expect(find.text('Food purchased'), findsOneWidget);
    expect(find.text('Feeding round coming up'), findsOneWidget);
    expect(find.text('Verified proof'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('completed request shows verified proof', (tester) async {
    await pumpDetails(tester, _request(age: const Duration(minutes: 10)));

    expect(find.text('Feeding completed'), findsWidgets);
    expect(find.text('Verified proof'), findsOneWidget);
    expect(find.text('Note from the operator'), findsOneWidget);
    expect(find.text('Al-Aziziyah, Makkah'), findsOneWidget);

    await tester.tap(find.text('Cats gathering for the meal'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('tapping a request on the requests tab opens its details', (
    tester,
  ) async {
    await pumpDetails(tester, _request(age: const Duration(seconds: 5)));
    Get.back<void>();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feeding Makkah Cats'));
    await tester.pumpAndSettle();
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Finding a local operator'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
