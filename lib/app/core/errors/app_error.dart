enum AppErrorType { network, server, validation, unauthorized, unknown }

/// Machine-readable error codes returned in the API's `code` field. Branch on
/// these, never on the translated `message`.
abstract final class ApiErrorCode {
  static const invalidCredentials = 'invalid_credentials';
  static const tokenExpired = 'token_expired';
  static const insufficientRole = 'insufficient_role';
  static const accountUnavailable = 'account_unavailable';
  static const sessionContextUnavailable = 'session_context_unavailable';
  static const feederProfileMissing = 'feeder_profile_missing';
  static const feederProfileNotApproved = 'feeder_profile_not_approved';
  static const taskNotFound = 'task_not_found';
  static const taskNotAssignedToUser = 'task_not_assigned_to_user';
  static const acceptanceDeadlineExpired = 'acceptance_deadline_expired';
  static const invalidStateTransition = 'invalid_state_transition';
  static const mediaLimitExceeded = 'media_limit_exceeded';
  static const mediaTooLarge = 'media_too_large';
  static const unsupportedMediaType = 'unsupported_media_type';
  static const mediaStorageUnavailable = 'media_storage_unavailable';
  static const proofMediaRequired = 'proof_media_required';
  static const gpsRequired = 'gps_required';
  static const gpsAccuracyUnacceptable = 'gps_accuracy_unacceptable';
  static const validationError = 'validation_error';
  static const rateLimited = 'rate_limited';
}

class AppError implements Exception {
  const AppError({
    required this.type,
    required this.message,
    this.statusCode,
    this.code,
    this.details = const {},
    this.canRetry = false,
  });

  final AppErrorType type;

  /// Readable, localized text to show the user.
  final String message;
  final int? statusCode;

  /// One of [ApiErrorCode], when the backend sent one.
  final String? code;
  final Map<String, dynamic> details;
  final bool canRetry;

  /// Per-field messages of a `validation_error`, keyed by request field.
  Map<String, String> get fieldErrors {
    final fields = details['fields'];
    if (fields is! Map) return const {};
    return {
      for (final entry in fields.entries) '${entry.key}': '${entry.value}',
    };
  }

  bool hasCode(String value) => code == value;

  @override
  String toString() => 'AppError($statusCode, $code): $message';
}
