import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Access and refresh tokens plus the stable device ID sent to the auth
/// service. Tokens live in the platform keychain; the device ID is not secret.
abstract class CredentialStore {
  CredentialStore(this._preferences);

  static const _deviceIdKey = 'zoovana_device_id_v1';
  final SharedPreferences _preferences;

  String? accessToken;
  String? refreshToken;

  bool get hasTokens => accessToken != null && refreshToken != null;

  /// Generated once on first launch and kept for logout and push updates.
  String get deviceId {
    final stored = _preferences.getString(_deviceIdKey);
    if (stored != null) return stored;
    final created = const Uuid().v4();
    _preferences.setString(_deviceIdKey, created);
    return created;
  }

  Future<void> saveDeviceId(String value) =>
      _preferences.setString(_deviceIdKey, value);

  /// Loads the stored tokens into memory.
  Future<void> load();

  Future<void> saveTokens({required String access, required String refresh});

  Future<void> clearTokens();
}

class SecureCredentialStore extends CredentialStore {
  SecureCredentialStore(super.preferences);

  static const _accessKey = 'zoovana_access_token';
  static const _refreshKey = 'zoovana_refresh_token';
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> load() async {
    accessToken = await _storage.read(key: _accessKey);
    refreshToken = await _storage.read(key: _refreshKey);
  }

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Keeps the seed session's demo tokens in preferences. Never used with real
/// tokens.
class DemoCredentialStore extends CredentialStore {
  DemoCredentialStore(super.preferences);

  static const _accessKey = 'zoovana_demo_access_v1';
  static const _refreshKey = 'zoovana_demo_refresh_v1';

  @override
  Future<void> load() async {
    accessToken = _preferences.getString(_accessKey);
    refreshToken = _preferences.getString(_refreshKey);
  }

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    await _preferences.setString(_accessKey, access);
    await _preferences.setString(_refreshKey, refresh);
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    await _preferences.remove(_accessKey);
    await _preferences.remove(_refreshKey);
  }
}
