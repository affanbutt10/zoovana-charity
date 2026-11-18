import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

abstract final class CheckoutPhone {
  static IsoCode iso(String country) => IsoCode.values.firstWhere(
    (c) => c.name == country.toUpperCase(),
    orElse: () => IsoCode.PK,
  );
  static PhoneNumber parse(String value, String country) => PhoneNumber.parse(
    value,
    destinationCountry: value.trim().startsWith('+') ? null : iso(country),
  );
  static String? international(String value, String country) {
    if (value.trim().isEmpty) return '';
    try {
      final number = parse(value, country);
      return number.isValid() ? number.international : null;
    } catch (_) {
      return null;
    }
  }

  static int maxNationalDigits(String country) {
    final region = iso(country);
    for (var n = 15; n > 0; n--) {
      final candidate = PhoneNumber(isoCode: region, nsn: '1' * n);
      if (candidate.isValidLength(type: PhoneNumberType.mobile) ||
          candidate.isValidLength(type: PhoneNumberType.fixedLine)) {
        return n;
      }
    }
    return 15;
  }
}

class CountryPhoneFormatter extends TextInputFormatter {
  CountryPhoneFormatter(this.country)
    : maximum = CheckoutPhone.maxNationalDigits(country);
  final String country;
  final int maximum;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final plus = newValue.text.trimLeft().startsWith('+');
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limit = plus
        ? 15
        : maximum + (digits.startsWith('0') && country != 'IT' ? 1 : 0);
    final value =
        '${plus ? '+' : ''}${digits.substring(0, digits.length.clamp(0, limit))}';
    if (value == newValue.text) return newValue;
    return TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
