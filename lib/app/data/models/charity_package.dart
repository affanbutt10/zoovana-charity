import 'package:get/get.dart';

import '../../../apis/core/api_response.dart';
import '../../core/services/app_locale.dart';

/// Formats an amount like the frames: `123.4`, `250`.
String formatAmount(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

/// Shows an API money string (`"75.00"`) without trailing zeros, e.g.
/// `75 SAR`, `123.4 SAR`. The string is never parsed into a double.
String formatMoney(String amount, String currency) {
  var text = amount.trim();
  if (text.contains('.')) {
    text = text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return currency.isEmpty ? text : '$text $currency';
}

/// A fixed feeding package. The donor picks exactly one per request.
class CharityPackage {
  const CharityPackage({
    required this.id,
    required this.name,
    required this.price,
    required this.impact,
    required this.food,
    this.currency = 'SAR',
    this.recommended = false,
    this.category = 'Food',
    this.rating = 4.8,
    this.calories = 120,
    this.image = 'assets/images/feeding_cat_food.jpg',
    this.imageUrl,
    this.mealCount,
    this.foodQuantityGrams,
    this.fulfilmentSlaHours,
  });

  final String id;
  final String name;

  /// Two-decimal money string from the API, e.g. `"75.00"`.
  final String price;
  final String currency;
  final String impact;
  final String food;
  final bool recommended;
  final String category;
  final double rating;
  final int calories;

  /// Bundled fallback artwork.
  final String image;
  final String? imageUrl;
  final int? mealCount;
  final int? foodQuantityGrams;
  final int? fulfilmentSlaHours;

  String get priceLabel => formatMoney(price, currency);

  /// Only for the legacy shelter flow's quantity totals.
  double get amount => double.tryParse(price) ?? 0;

  /// `GET /programs/{id}/packages` item.
  factory CharityPackage.fromApi(Map<String, dynamic> json) {
    final meals = json['meal_count'] == null
        ? null
        : json.integer('meal_count');
    final grams = json['food_quantity_grams'] == null
        ? null
        : json.integer('food_quantity_grams');
    return CharityPackage(
      id: json.str('id'),
      name: AppLocale.pick(
        json.strOrNull('name_en'),
        json.strOrNull('name_ar'),
        json.strOrNull('name_ur'),
      ),
      price: json.str('price', '0.00'),
      currency: json.str('currency', 'PKR'),
      impact: meals == null
          ? ''
          : 'Approximately @count meals'.trParams({'count': '$meals'}),
      food: AppLocale.pick(
        json.strOrNull('description_en'),
        json.strOrNull('description_ar'),
        json.strOrNull('description_ur'),
      ),
      recommended: json.flag('is_popular'),
      imageUrl: json.strOrNull('image_url'),
      mealCount: meals,
      foodQuantityGrams: grams,
      fulfilmentSlaHours: json['fulfilment_sla_hours'] == null
          ? null
          : json.integer('fulfilment_sla_hours'),
    );
  }

  factory CharityPackage.fromJson(Map<String, dynamic> json) {
    return CharityPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      price: '${json['price'] ?? json['amount'] ?? '0'}',
      currency: json['currency'] as String? ?? 'SAR',
      impact: json['impact'] as String,
      food: json['food'] as String,
      recommended: json['recommended'] as bool? ?? false,
      category: json['category'] as String? ?? 'Food',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      calories: (json['calories'] as num?)?.toInt() ?? 120,
      image: json['image'] as String? ?? 'assets/images/feeding_cat_food.jpg',
      mealCount: (json['mealCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'currency': currency,
    'impact': impact,
    'food': food,
    'recommended': recommended,
    'category': category,
    'rating': rating,
    'calories': calories,
    'image': image,
    'mealCount': mealCount,
  };
}

/// A selected food item and its draft quantity. Backend submission currently
/// supports one line with quantity one; larger baskets remain local drafts.
class DonationLine {
  const DonationLine({required this.item, required this.quantity});

  final CharityPackage item;
  final int quantity;

  double get total => item.amount * quantity;
  int get totalMinorUnits => moneyMinorUnits(item.price) * quantity;
  String get totalLabel => formatMinorMoney(totalMinorUnits, item.currency);
}

/// Contact and notification choices sent with `POST /requests`.
class DonorDetails {
  const DonorDetails({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.countryCode = 'PK',
    this.dedication = '',
    this.isAnonymous = false,
    this.notifyPush = true,
    this.notifyEmail = true,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String dedication;
  final bool isAnonymous;
  final bool notifyPush;
  final bool notifyEmail;
}

/// Two-decimal API money is calculated in integer minor units, without doubles.
int moneyMinorUnits(String amount) {
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(amount.trim());
  if (match == null) return 0;
  return int.parse(match.group(1)!) * 100 +
      int.parse((match.group(2) ?? '').padRight(2, '0'));
}

String formatMinorMoney(int units, String currency) => formatMoney(
  '${units ~/ 100}.${(units % 100).toString().padLeft(2, '0')}',
  currency,
);
String basketTotalLabel(List<DonationLine> lines) => lines.isEmpty
    ? '—'
    : formatMinorMoney(
        lines.fold<int>(0, (total, line) => total + line.totalMinorUnits),
        lines.first.item.currency,
      );
