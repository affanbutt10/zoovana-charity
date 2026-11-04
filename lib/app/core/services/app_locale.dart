import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app language: English, Arabic or Urdu. Chosen in the app, saved on
/// the device, sent as `Accept-Language`, and used to pick localized API
/// fields. Arabic and Urdu lay the app out right to left.
abstract final class AppLocale {
  static const supported = [Locale('en'), Locale('ar'), Locale('ur')];

  /// Each language in its own script, for the picker.
  static const names = {'en': 'English', 'ar': 'العربية', 'ur': 'اردو'};

  static const _key = 'app_language_v1';

  /// The saved choice, else the phone's language when supported, else
  /// English.
  static Locale get initial {
    final saved = Get.isRegistered<SharedPreferences>()
        ? Get.find<SharedPreferences>().getString(_key)
        : null;
    final code =
        saved ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(names.containsKey(code) ? code : 'en');
  }

  static String get code {
    final languageCode =
        (Get.locale ?? WidgetsBinding.instance.platformDispatcher.locale)
            .languageCode;
    return names.containsKey(languageCode) ? languageCode : 'en';
  }

  static bool get isArabic => code == 'ar';

  static bool get isRtl => code != 'en';

  static Future<void> change(String code) async {
    if (!names.containsKey(code)) return;
    await Get.find<SharedPreferences>().setString(_key, code);
    await Get.updateLocale(Locale(code));
  }

  /// Picks the API value for the app language. Urdu falls back to English
  /// while the API has no Urdu text.
  static String pick(String? en, String? ar, [String? ur]) {
    final value = switch (code) {
      'ar' => ar,
      'ur' => ur,
      _ => en,
    };
    if (value != null && value.isNotEmpty) return value;
    return en ?? ar ?? '';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Translated short month name, e.g. "Nov".
  static String shortMonth(int month) => _months[month - 1].tr;
}
