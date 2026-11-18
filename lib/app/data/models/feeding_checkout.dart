import '../../../apis/core/api_response.dart';
import 'charity_package.dart';
import 'package:intl/intl.dart';
import '../../core/services/app_locale.dart';

List<Map<String, dynamic>> basketBody(List<DonationLine> lines) => [
  for (final line in lines)
    {'package_id': line.item.id, 'quantity': line.quantity},
];
String basketSignature(List<DonationLine> lines) =>
    (lines.map((l) => '${l.item.id}:${l.quantity}').toList()..sort()).join('|');

class FeedingQuote {
  FeedingQuote.fromJson(Map<String, dynamic> json)
    : amountMinor = json.integer('amount_minor'),
      currency = json.str('currency'),
      maxQuantity = json.object('limits')?.integer('max_item_quantity') ?? 0,
      maxLines = json.object('limits')?.integer('max_line_items') ?? 0,
      items = json.objects('items');
  final int amountMinor, maxQuantity, maxLines;
  final String currency;
  final List<Map<String, dynamic>> items;
  String get label =>
      '${NumberFormat.decimalPatternDigits(locale: AppLocale.code, decimalDigits: 2).format(amountMinor / 100)} $currency';
  bool matches(List<DonationLine> lines) =>
      basketSignature(lines) ==
      (items
              .map((i) => '${i.str('package_id')}:${i.integer('quantity')}')
              .toList()
            ..sort())
          .join('|');
}

class FeedingPaymentMethod {
  FeedingPaymentMethod.fromJson(Map<String, dynamic> json)
    : id = json.str('id'),
      providerMethod = json.str('provider_method'),
      platforms = json.strings('platforms');
  final String id, providerMethod;
  final List<String> platforms;
  String get label => switch (id) {
    'card' => 'Pay with Card',
    'apple_pay' => 'Apple Pay',
    'stc_pay' => 'STC Pay',
    _ => id,
  };
}

class FeedingPaymentMethods {
  FeedingPaymentMethods.fromJson(Map<String, dynamic> json)
    : provider = json.str('provider'),
      currencies = json.strings('currencies'),
      methods = [
        for (final m in json.objects('methods'))
          FeedingPaymentMethod.fromJson(m),
      ],
      savedCards = json.object('saved_cards')?.flag('supported') ?? false;
  final String provider;
  final List<String> currencies;
  final List<FeedingPaymentMethod> methods;
  final bool savedCards;
}

/// Only server-provided provider configuration; never cardholder data.
class FeedingPaymentIntent {
  FeedingPaymentIntent.fromJson(Map<String, dynamic> json)
    : provider = json.str('provider'),
      payload = json.object('client_payload') ?? const {};
  final String provider;
  final Map<String, dynamic> payload;
}
