import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService(this._preferences);

  final SharedPreferences _preferences;

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> value) {
    return _preferences.setString(key, jsonEncode(value));
  }

  List<Map<String, dynamic>> readJsonList(String key) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> remove(String key) => _preferences.remove(key);
}
