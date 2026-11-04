import 'dart:io';

abstract final class AppConfig {
  static const appName = 'Zoovana';

  /// Auth service root. Defaults to the live server; override with
  /// `--dart-define=CHARITY_AUTH_URL=http://192.168.1.10:8001/api/v1`.
  static const authBaseUrl = String.fromEnvironment(
    'CHARITY_AUTH_URL',
    defaultValue: 'https://api.auth.zoovana.net/api/v1',
  );

  /// Feeding module root inside the Marketplace service. Defaults to
  /// the live server; override with
  /// `--dart-define=CHARITY_FEEDING_URL=http://192.168.1.10:8012/api/v1/feeding`.
  static const feedingBaseUrl = String.fromEnvironment(
    'CHARITY_FEEDING_URL',
    defaultValue: 'https://api.market.zoovana.net/api/v1/feeding',
  );

  /// Runs on the built-in demo data instead of the backend:
  /// `--dart-define=CHARITY_DEMO=true`.
  static const useDemoData = bool.fromEnvironment('CHARITY_DEMO');

  /// Widget tests always use the demo data, so they never call the servers.
  static bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  static bool get useRemoteApi =>
      !useDemoData &&
      !_isTest &&
      authBaseUrl.isNotEmpty &&
      feedingBaseUrl.isNotEmpty;

  /// Shows the mock checkout for draft requests. Only dev and staging fund
  /// requests this way while payments are out of scope.
  static const enableMockCheckout = bool.fromEnvironment(
    'CHARITY_MOCK_CHECKOUT',
    defaultValue: true,
  );

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);

  /// Media uploads get longer, since videos may be up to 100 MB.
  static const uploadTimeout = Duration(minutes: 5);

  static const deepLinkScheme = 'zoovana-charity';
}
