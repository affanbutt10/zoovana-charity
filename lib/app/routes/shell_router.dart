import 'package:get/get.dart';

import '../data/models/charity_session.dart';
import '../data/repositories/charity_repository.dart';
import '../data/repositories/feeder_repository.dart';
import '../data/repositories/session_repository.dart';
import 'app_routes.dart';

/// Picks the shell from the backend's `app_mode` and the operator's
/// verification status. The app never guesses a role.
abstract final class ShellRouter {
  static String routeFor(CharitySession session) => switch (session.appMode) {
    AppMode.donor => AppRoutes.home,
    AppMode.unsupported => AppRoutes.unsupported,
    AppMode.operator when !session.hasFeederProfile => AppRoutes.operatorApply,
    AppMode.operator
        when session.verificationStatus == VerificationStatus.approved =>
      AppRoutes.providerHome,
    AppMode.operator => AppRoutes.operatorStatus,
  };

  /// Replaces the stack with [session]'s shell.
  static void open(CharitySession session) =>
      Get.offAllNamed<void>(routeFor(session));

  /// Logs out, drops this account's cached data and shows the auth screens.
  static Future<void> signOut() async {
    await Get.find<SessionRepository>().signOut();
    await Get.find<CharityRepository>().clearCache();
    Get.find<FeederRepository>().clear();
    Get.offAllNamed<void>(AppRoutes.auth);
  }

  /// Whether a deep link such as `zoovana-charity://operator/task/{id}`
  /// belongs to the shell [session] opens.
  static bool linkMatches(CharitySession session, String shell) =>
      switch (session.appMode) {
        AppMode.donor => shell == 'donor',
        AppMode.operator => shell == 'operator',
        AppMode.unsupported => false,
      };
}
