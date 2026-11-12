import 'package:flutter/services.dart';

abstract final class InputRules {
  static bool email(String value) =>
      value.trim().length <= 254 &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());

  static bool phone(String value) {
    final text = value.replaceAll(RegExp(r'[\s()-]'), '');
    if (text.startsWith('+92')) {
      return RegExp(r'^\+92[1-9]\d{9}$').hasMatch(text);
    }
    if (text.startsWith('+966')) {
      return RegExp(r'^\+966[1-9]\d{8}$').hasMatch(text);
    }
    if (text.startsWith('+')) {
      return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(text);
    }
    if (text.startsWith('03')) {
      return RegExp(r'^03\d{9}$').hasMatch(text);
    }
    if (text.startsWith('05')) {
      return RegExp(r'^05\d{8}$').hasMatch(text);
    }
    return RegExp(r'^0?[1-9]\d{7,9}$').hasMatch(text) ||
        RegExp(r'^[1-9]\d{10}$').hasMatch(text);
  }

  static bool name(String value) =>
      value.trim().length >= 2 && value.trim().length <= 100;
}

/// Keeps one leading country-code plus and limits digits, including pasted text.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final plus = raw.trimLeft().startsWith('+');
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final limit = plus
        ? digits.startsWith('966') || digits.startsWith('92')
              ? 12
              : 15
        : digits.startsWith('05')
        ? 10
        : 11;
    final text =
        '${plus ? '+' : ''}${digits.substring(0, digits.length.clamp(0, limit))}';
    if (text == raw) return newValue;
    final beforeCursor = raw.substring(
      0,
      newValue.selection.extentOffset.clamp(0, raw.length),
    );
    final offset =
        (beforeCursor.replaceAll(RegExp(r'\D'), '').length +
                (plus && beforeCursor.trimLeft().startsWith('+') ? 1 : 0))
            .clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class AmountInputFormatter extends TextInputFormatter {
  const AmountInputFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => RegExp(r'^\d{0,9}(\.\d{0,2})?$').hasMatch(newValue.text)
      ? newValue
      : oldValue;
}
