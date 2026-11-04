import '../../../apis/core/api_response.dart';

/// Which shell the backend says this account opens.
enum AppMode {
  donor,
  operator,
  unsupported;

  static AppMode fromCode(String? code) => switch (code) {
    'donor' => donor,
    'operator' => operator,
    _ => unsupported,
  };
}

/// Operator (feeder) verification state.
enum VerificationStatus {
  pendingReview('pending_review'),
  approved('approved'),
  rejected('rejected'),
  suspended('suspended'),
  unknown('unknown');

  const VerificationStatus(this.code);
  final String code;

  static VerificationStatus fromCode(String? code) =>
      values.firstWhere((status) => status.code == code, orElse: () => unknown);
}

class SessionUser {
  const SessionUser({required this.id, required this.email, this.fullName});

  final String id;
  final String email;
  final String? fullName;

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
    id: json.str('id'),
    email: json.str('email'),
    fullName: json.strOrNull('full_name'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
  };
}

/// The normalized account context returned by login, refresh and session.
class CharitySession {
  const CharitySession({
    required this.appMode,
    required this.user,
    this.accountType = '',
    this.roles = const [],
    this.feederProfileId,
    this.verificationStatus,
    this.deviceId,
  });

  final String accountType;
  final List<String> roles;
  final AppMode appMode;
  final SessionUser user;

  /// Null when an operator account has not applied yet.
  final String? feederProfileId;
  final VerificationStatus? verificationStatus;
  final String? deviceId;

  bool get hasFeederProfile => feederProfileId != null;

  factory CharitySession.fromJson(Map<String, dynamic> json) {
    final profile = json.object('feeder_profile');
    return CharitySession(
      accountType: json.str('account_type'),
      roles: json.strings('roles'),
      appMode: AppMode.fromCode(json.strOrNull('app_mode')),
      user: SessionUser.fromJson(json.object('user') ?? const {}),
      feederProfileId: profile?.strOrNull('id'),
      verificationStatus: profile == null
          ? null
          : VerificationStatus.fromCode(
              profile.strOrNull('verification_status'),
            ),
      deviceId: json.strOrNull('device_id'),
    );
  }

  Map<String, dynamic> toJson() => {
    'account_type': accountType,
    'roles': roles,
    'app_mode': appMode.name,
    'user': user.toJson(),
    'feeder_profile': feederProfileId == null
        ? null
        : {
            'id': feederProfileId,
            'verification_status': verificationStatus?.code,
          },
    'device_id': deviceId,
  };
}

/// A login or refresh result: the session plus its tokens.
class AuthResult {
  const AuthResult({
    required this.session,
    required this.accessToken,
    required this.refreshToken,
  });

  final CharitySession session;
  final String accessToken;
  final String refreshToken;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    session: CharitySession.fromJson(json),
    accessToken: json.str('access_token'),
    refreshToken: json.str('refresh_token'),
  );
}

/// The donor's account record (`/charity/auth/profile`).
class DonorAccount {
  const DonorAccount({
    required this.email,
    required this.fullName,
    this.phoneNumber = '',
  });

  final String email;
  final String fullName;

  /// Set at sign-up; the API doesn't let it change afterwards.
  final String phoneNumber;

  factory DonorAccount.fromJson(Map<String, dynamic> json) => DonorAccount(
    email: json.str('email'),
    fullName: json.str('full_name'),
    phoneNumber: json.str('phone_number'),
  );
}
