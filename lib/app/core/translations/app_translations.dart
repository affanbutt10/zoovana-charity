import 'package:get/get.dart';

import 'parts/checkout.dart';
import 'parts/common.dart';
import 'parts/donor.dart';
import 'parts/operator.dart';

/// Arabic and Urdu text, keyed by the English text. English needs no map:
/// a missing key shows the key itself. Placeholders use `@name` with
/// `trParams`.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'ar': {...commonAr, ...donorAr, ...checkoutAr, ...operatorAr},
    'ur': {...commonUr, ...donorUr, ...checkoutUr, ...operatorUr},
  };
}
