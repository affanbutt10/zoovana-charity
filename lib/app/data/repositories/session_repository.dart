import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_error.dart';
import '../../core/errors/app_error_mapper.dart';
import '../../core/services/app_locale.dart';
import '../../core/services/credential_store.dart';
import '../datasources/auth_data_source.dart';
import '../models/charity_session.dart';

/// Result of checking a stored session at app start.
sealed class SessionCheck {
  const SessionCheck();
}

/// The session is valid; route by its mode.
class SessionReady extends SessionCheck {
  const SessionReady(this.session);
  final CharitySession session;
}

/// No usable login; show the auth screens.
class SessionSignedOut extends SessionCheck {
  const SessionSignedOut();
}

/// Signed in, but this account can't use the app (`insufficient_role`).
class SessionUnsupported extends SessionCheck {
  const SessionUnsupported();
}

/// The session couldn't be confirmed right now; keep the login and retry.
class SessionUnavailable extends SessionCheck {
  const SessionUnavailable(this.error);
  final AppError error;
}

/// Owns tokens, the device ID and the current account context.
class SessionRepository {
  SessionRepository(this._preferences, this._credentials, this._dataSource);

  static const _sessionKey = 'zoovana_session_context_v2';
  final SharedPreferences _preferences;
  final CredentialStore _credentials;
  final AuthDataSource _dataSource;

  CharitySession? _current;

  /// The latest session context; cached so names render before it refreshes.
  CharitySession? get current => _current ??= _readCached();

  bool get hasActiveSession => _credentials.hasTokens;

  String? get displayName {
    final name = current?.user.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return _preferences.getString('profile_name');
  }

  String? get email => current?.user.email;

  /// Called after a refresh returns a session whose mode or operator
  /// status differs from the previous one, so the app can re-route.
  void Function(CharitySession session)? onSessionChanged;

  /// Push token from Firebase, once push is configured.
  String? fcmToken;

  Future<void> initialize() => _credentials.load();

  Future<CharitySession> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _dataSource.login(
      email: email,
      password: password,
      deviceId: _credentials.deviceId,
      locale: AppLocale.code,
      fcmToken: fcmToken,
    );
    return _store(result);
  }

  Future<CharitySession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _dataSource.register(
      fullName: fullName,
      email: email,
      password: password,
    );
    return signIn(email: email, password: password);
  }

  Future<DonorAccount> donorAccount() => _dataSource.fetchDonorAccount();

  Future<DonorAccount> updateDonorName(String fullName) async {
    final account = await _dataSource.updateDonorAccount(fullName: fullName);
    await _preferences.setString('profile_name', account.fullName);
    try {
      // The cached session still carries the old name the headers show.
      await reload();
    } catch (_) {
      // The name is saved; headers catch up on the next session refresh.
    }
    return account;
  }

  /// Deactivates the donor account, then clears the local login.
  Future<void> deleteDonorAccount() async {
    await _dataSource.deleteDonorAccount();
    await _clear();
  }

  /// Confirms the stored login before any shell is drawn.
  Future<SessionCheck> restore() async {
    if (!hasActiveSession) return const SessionSignedOut();
    try {
      return SessionReady(await _remember(await _dataSource.session()));
    } catch (exception) {
      final error = AppErrorMapper.map(exception);
      if (error.hasCode(ApiErrorCode.insufficientRole)) {
        return const SessionUnsupported();
      }
      if (error.type == AppErrorType.unauthorized) {
        await _clear();
        return const SessionSignedOut();
      }
      return SessionUnavailable(error);
    }
  }

  /// Re-reads the session, e.g. after `feeder_approved` or applying.
  Future<CharitySession> reload() async =>
      _remember(await _dataSource.session());

  /// Used by the API client on `token_expired`. Returns the new access token,
  /// or null after clearing a login that can't be renewed.
  Future<String?> refreshAccessToken() async {
    final refreshToken = _credentials.refreshToken;
    if (refreshToken == null) return null;
    try {
      final result = await _dataSource.refresh(
        refreshToken: refreshToken,
        deviceId: _credentials.deviceId,
        locale: AppLocale.code,
        fcmToken: fcmToken,
      );
      final previous = _current;
      final session = await _store(result);
      final changed =
          previous != null &&
          (previous.appMode != session.appMode ||
              previous.verificationStatus != session.verificationStatus);
      if (changed) onSessionChanged?.call(session);
      return result.accessToken;
    } catch (exception) {
      final error = AppErrorMapper.map(exception);
      if (error.type == AppErrorType.unauthorized) await _clear();
      return null;
    }
  }

  /// Sends a rotated Firebase token for this device.
  Future<void> updatePushToken(String token) async {
    fcmToken = token;
    if (!hasActiveSession) return;
    await _dataSource.updateDevice(
      deviceId: _credentials.deviceId,
      fcmToken: token,
      locale: AppLocale.code,
    );
  }

  /// Stops push to this device and revokes the refresh token. Local tokens
  /// are cleared even when the call fails.
  Future<void> signOut() async {
    try {
      if (hasActiveSession) {
        await _dataSource.logout(
          deviceId: _credentials.deviceId,
          refreshToken: _credentials.refreshToken,
        );
      }
    } catch (_) {
      // The tokens are dropped locally either way.
    } finally {
      await _clear();
    }
  }

  Future<CharitySession> _store(AuthResult result) async {
    await _credentials.saveTokens(
      access: result.accessToken,
      refresh: result.refreshToken,
    );
    final deviceId = result.session.deviceId;
    if (deviceId != null && deviceId.isNotEmpty) {
      await _credentials.saveDeviceId(deviceId);
    }
    return _remember(result.session);
  }

  Future<CharitySession> _remember(CharitySession session) async {
    _current = session;
    await _preferences.setString(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  CharitySession? _readCached() {
    final raw = _preferences.getString(_sessionKey);
    if (raw == null) return null;
    try {
      return CharitySession.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> _clear() async {
    _current = null;
    await _credentials.clearTokens();
    await _preferences.remove(_sessionKey);
  }
}
