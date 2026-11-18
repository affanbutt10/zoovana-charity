import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:zoovana_charity/app/core/forms/checkout_phone.dart';
import 'package:zoovana_charity/app/core/theme/app_theme.dart';
import 'package:zoovana_charity/app/shared/widgets/country_phone_field.dart';

void main() {
  test(
    'country parsing normalizes national numbers and rejects invalid numbers',
    () {
      expect(CheckoutPhone.international('03001234567', 'PK'), '+923001234567');
      expect(CheckoutPhone.international('501234567', 'SA'), '+966501234567');
      expect(CheckoutPhone.international('07400123456', 'GB'), '+447400123456');
      expect(CheckoutPhone.international('300123456789999', 'PK'), isNull);
      expect(CheckoutPhone.international('', 'SA'), '');
      expect(CheckoutPhone.maxNationalDigits('PK'), 10);
      final value = CountryPhoneFormatter('SA').formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '501234567123456'),
      );
      expect(value.text, '501234567');
    },
  );
  testWidgets(
    'searchable picker changes flag and code and stays responsive in RTL',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String selected = 'PK';
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 800),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CountryPhoneField(
                      controller: controller,
                      countryCode: selected,
                      onCountryChanged: (value) =>
                          setState(() => selected = value),
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('+92'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Saudi Arabia');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Saudi Arabia').last);
      await tester.pumpAndSettle();
      expect(selected, 'SA');
      expect(find.text('+966'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '501234567999999');
      await tester.pumpAndSettle();
      expect(controller.text, '501234567');
      expect(tester.takeException(), isNull);
    },
  );
}
