/// Auth service paths, relative to `AppConfig.authBaseUrl`.
abstract final class AuthEndpoints {
  static const login = '/charity/auth/login';
  static const session = '/charity/auth/session';
  static const refresh = '/charity/auth/refresh';
  static const devices = '/charity/auth/devices';
  static const logout = '/charity/auth/logout';
  static const register = '/mp-clients/register';

  /// The signed-in donor's account (GET, PATCH).
  static const profile = '/charity/auth/profile';

  /// Deletes and anonymises the signed-in account.
  static const account = '/charity/auth/account';
}

/// Feeding paths, relative to `AppConfig.feedingBaseUrl`.
abstract final class FeedingEndpoints {
  // Donor
  static const programs = '/programs';
  static String program(String id) => '/programs/$id';
  static String packages(String programId) => '/programs/$programId/packages';
  static String highlights(String programId) =>
      '/programs/$programId/highlights';
  static String zones(String programId) => '/programs/$programId/zones';
  static const requests = '/requests';
  static const myRequests = '/requests/my';
  static String request(String id) => '/requests/$id';
  static String cancelRequest(String id) => '/requests/$id/cancel';
  static String paymentIntent(String id) => '/requests/$id/payment-intent';

  // Operator
  static const applyFeeder = '/feeders/apply';
  static const feederMe = '/feeders/me';
  static const feederDashboard = '/feeder/dashboard/summary';
  static const feederTasks = '/feeder/tasks';
  static String task(String id) => '/feeder/tasks/$id';
  static String acceptTask(String id) => '/feeder/tasks/$id/accept';
  static String declineTask(String id) => '/feeder/tasks/$id/decline';
  static String taskStatus(String id) => '/feeder/tasks/$id/status';
  static String taskMedia(String id) => '/feeder/tasks/$id/media';
  static String taskMediaItem(String id, String mediaId) =>
      '/feeder/tasks/$id/media/$mediaId';
  static String taskUploadSignature(String id) =>
      '/feeder/tasks/$id/media/upload-signature';
  static String taskRegisterMedia(String id) =>
      '/feeder/tasks/$id/media/register';
  static String taskProof(String id) => '/feeder/tasks/$id/proof';
  static const feederPayouts = '/feeder/payouts';

  // Both shells
  static const notifications = '/notifications';
  static String readNotification(String id) => '/notifications/$id/read';
  static const readAllNotifications = '/notifications/read-all';
}
