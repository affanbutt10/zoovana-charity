import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoovana_charity/app/core/forms/input_rules.dart';
import 'package:zoovana_charity/app/shared/widgets/dismiss_keyboard.dart';
import 'package:zoovana_charity/app/shared/widgets/zoovana_ui.dart';

void main() {
  test(
    'phone validation rejects invalid local lengths and country formats',
    () {
      for (final phone in [
        '03123456789',
        '+923123456789',
        '0512345678',
        '+966512345678',
        '+441234567890',
      ]) {
        expect(InputRules.phone(phone), isTrue, reason: phone);
      }
      for (final phone in [
        '',
        '123',
        '031234567891234',
        '+9203123456789',
        '+9665123',
        '03hello123456789',
        '++++++++',
      ]) {
        expect(InputRules.phone(phone), isFalse, reason: phone);
      }
      expect(InputRules.email('user@example.com'), isTrue);
      expect(InputRules.email('user@'), isFalse);
      expect(InputRules.email('user name@example.com'), isFalse);
    },
  );

  test(
    'phone formatter limits typed and pasted national/international numbers',
    () {
      const formatter = PhoneInputFormatter();
      String format(String input) => formatter
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(
              text: input,
              selection: TextSelection.collapsed(offset: input.length),
            ),
          )
          .text;
      expect(format('031234567891234'), '03123456789');
      expect(format('+92 312-345678901234'), '+923123456789');
      expect(format('051234567891234'), '0512345678');
      expect(format('abc03123456789'), '03123456789');
      expect(format('++923123456789'), '+923123456789');
    },
  );

  testWidgets('shared numeric fields enforce length and phone rules', (
    tester,
  ) async {
    final phone = TextEditingController();
    final count = TextEditingController();
    addTearDown(phone.dispose);
    addTearDown(count.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              LabeledField(
                label: 'Phone',
                controller: phone,
                keyboardType: TextInputType.phone,
              ),
              LabeledField(
                label: 'Count',
                controller: count,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), '031234567891234');
    expect(phone.text, '03123456789');
    await tester.enterText(find.byType(TextField).at(1), '123456789012345');
    expect(count.text, '123456');
  });

  testWidgets(
    'touch outside hides keyboard and field/button taps keep working',
    (tester) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => DismissKeyboard(child: child!),
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: first),
                TextField(focusNode: second),
                TextButton(
                  onPressed: () => pressed = true,
                  child: const Text('Continue'),
                ),
                const Expanded(child: SizedBox.expand()),
              ],
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(TextField).first);
      expect(first.hasFocus, isTrue);
      await tester.tapAt(const Offset(200, 400));
      await tester.pump();
      expect(first.hasFocus, isFalse);
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.tap(find.byType(TextField).last);
      await tester.pump();
      expect(second.hasFocus, isTrue);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(pressed, isTrue);
      expect(second.hasFocus, isFalse);
    },
  );
}
