import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../apis/core/api_client.dart';
import '../../../apis/core/api_endpoints.dart';
import '../../../apis/core/api_response.dart';
import '../../core/errors/app_error.dart';
import '../models/charity_session.dart';

abstract interface class AuthDataSource {
  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceId,
    required String locale,
    String? fcmToken,
  });

  /// The current token's account context (`GET /charity/auth/session`).
  Future<CharitySession> session();

  Future<AuthResult> refresh({
    required String refreshToken,
    required String deviceId,
    required String locale,
    String? fcmToken,
  });

  Future<void> updateDevice({
    required String deviceId,
    required String fcmToken,
    required String locale,
  });

  Future<void> logout({required String deviceId, String? refreshToken});

  /// Creates a donor account. Sign in afterwards to get `app_mode`.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// The signed-in donor's account details.
  Future<DonorAccount> fetchDonorAccount();

  Future<DonorAccount> updateDonorAccount({required String fullName});

  /// Deactivates the signed-in donor's account.
  Future<void> deleteDonorAccount();
}

class RemoteAuthDataSource implements AuthDataSource {
  RemoteAuthDataSource(this._client);

  final ApiClient _client;
  Dio get _dio => _client.auth;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceId,
    required String locale,
    String? fcmToken,
  }) async {
    final response = await _dio.post<dynamic>(
      AuthEndpoints.login,
      data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
        'locale': locale,
        'fcm_token': ?fcmToken,
      },
      options: ApiClient.anonymous,
    );
    return AuthResult.fromJson(response.dataMap);
  }

  @override
  Future<CharitySession> session() async {
    final response = await _dio.get<dynamic>(AuthEndpoints.session);
    return CharitySession.fromJson(response.dataMap);
  }

  @override
  Future<AuthResult> refresh({
    required String refreshToken,
    required String deviceId,
    required String locale,
    String? fcmToken,
  }) async {
    final response = await _dio.post<dynamic>(
      AuthEndpoints.refresh,
      data: {
        'refresh_token': refreshToken,
        'device_id': deviceId,
        'locale': locale,
        'fcm_token': ?fcmToken,
      },
      options: ApiClient.anonymous,
    );
    return AuthResult.fromJson(response.dataMap);
  }

  @override
  Future<void> updateDevice({
    required String deviceId,
    required String fcmToken,
    required String locale,
  }) => _dio.put<dynamic>(
    AuthEndpoints.devices,
    data: {'device_id': deviceId, 'fcm_token': fcmToken, 'locale': locale},
  );

  @override
  Future<void> logout({required String deviceId, String? refreshToken}) =>
      _dio.post<dynamic>(
        AuthEndpoints.logout,
        data: {'device_id': deviceId, 'refresh_token': ?refreshToken},
      );

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) => _dio.post<dynamic>(
    AuthEndpoints.register,
    data: {'full_name': fullName, 'email': email, 'password': password},
    options: ApiClient.anonymous,
  );

  @override
  Future<DonorAccount> fetchDonorAccount() async => DonorAccount.fromJson(
    (await _dio.get<dynamic>(AuthEndpoints.profile)).dataMap,
  );

  @override
  Future<DonorAccount> updateDonorAccount({required String fullName}) async =>
      DonorAccount.fromJson(
        (await _dio.patch<dynamic>(
          AuthEndpoints.profile,
          data: {'full_name': fullName},
        )).dataMap,
      );

  @override
  Future<void> deleteDonorAccount() =>
      _dio.delete<dynamic>(AuthEndpoints.account);
}

/// Offline accounts for demos and tests. The seed backend decides the mode
/// the same way the real one does: from the account, never from the client.
///
/// - `operator@zoovana.demo`: approved operator
/// - `applicant@zoovana.demo`: operator who hasn't applied yet
/// - `review@zoovana.demo`: operator whose application is under review
/// - `staff@zoovana.demo`: staff account the app can't use
/// - any other email: donor
class SeedAuthDataSource implements AuthDataSource {
  SeedAuthDataSource(this._preferences);

  static const _sessionKey = 'zoovana_demo_session_v1';
  final SharedPreferences _preferences;

  CharitySession _sessionFor(String email, {String? fullName}) {
    final user = SessionUser(
      id: 'demo-${email.hashCode.abs()}',
      email: email,
      fullName:
          fullName ??
          _preferences.getString('profile_name') ??
          (email.startsWith('operator') ? 'Ahmad Bahsas' : null),
    );
    return switch (email.toLowerCase()) {
      'operator@zoovana.demo' => CharitySession(
        accountType: 'staff',
        roles: const ['feeder'],
        appMode: AppMode.operator,
        user: user,
        feederProfileId: 'demo-feeder',
        verificationStatus: VerificationStatus.approved,
      ),
      'applicant@zoovana.demo' => CharitySession(
        accountType: 'staff',
        roles: const ['feeder'],
        appMode: AppMode.operator,
        user: user,
      ),
      'review@zoovana.demo' => CharitySession(
        accountType: 'staff',
        roles: const ['feeder'],
        appMode: AppMode.operator,
        user: user,
        feederProfileId: 'demo-feeder-review',
        verificationStatus: VerificationStatus.pendingReview,
      ),
      'staff@zoovana.demo' => CharitySession(
        accountType: 'staff',
        roles: const ['support'],
        appMode: AppMode.unsupported,
        user: user,
      ),
      _ => CharitySession(
        accountType: 'mp_client',
        roles: const ['marketplace_client'],
        appMode: AppMode.donor,
        user: user,
      ),
    };
  }

  Future<AuthResult> _issue(CharitySession session) async {
    await _preferences.setString(_sessionKey, session.user.email);
    return AuthResult(
      session: session,
      accessToken: 'demo-access-${session.user.id}',
      refreshToken: 'demo-refresh-${session.user.id}',
    );
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required String deviceId,
    required String locale,
    String? fcmToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _issue(_sessionFor(email));
  }

  @override
  Future<CharitySession> session() async {
    final email = _preferences.getString(_sessionKey);
    if (email == null) {
      throw AppError(
        type: AppErrorType.unauthorized,
        statusCode: 401,
        code: ApiErrorCode.invalidCredentials,
        message: 'Please sign in again.'.tr,
      );
    }
    return _sessionFor(email);
  }

  @override
  Future<AuthResult> refresh({
    required String refreshToken,
    required String deviceId,
    required String locale,
    String? fcmToken,
  }) async => _issue(await session());

  @override
  Future<void> updateDevice({
    required String deviceId,
    required String fcmToken,
    required String locale,
  }) async {}

  @override
  Future<void> logout({required String deviceId, String? refreshToken}) =>
      _preferences.remove(_sessionKey);

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) => _preferences.setString('profile_name', fullName);

  @override
  Future<DonorAccount> fetchDonorAccount() async {
    final session = await this.session();
    return DonorAccount(
      email: session.user.email,
      fullName: session.user.fullName ?? '',
      phoneNumber: _preferences.getString('profile_phone') ?? '',
    );
  }

  @override
  Future<DonorAccount> updateDonorAccount({required String fullName}) async {
    await _preferences.setString('profile_name', fullName);
    return fetchDonorAccount();
  }

  @override
  Future<void> deleteDonorAccount() => _preferences.remove(_sessionKey);

  /// Lets the demo move an applicant to "under review" after applying.
  Future<void> markApplied() async {
    final email = _preferences.getString(_sessionKey);
    if (email == 'applicant@zoovana.demo') {
      await _preferences.setString(_sessionKey, 'review@zoovana.demo');
    }
  }
}
