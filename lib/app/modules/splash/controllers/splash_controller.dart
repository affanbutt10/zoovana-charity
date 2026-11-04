import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/deep_link_service.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/shell_router.dart';

/// Holds the splash until the stored session is confirmed, so no shell is
/// drawn for the wrong account.
class SplashController extends GetxController {
  /// Set when the session couldn't be confirmed; the splash offers a retry
  /// instead of signing out.
  String? error;
  bool isChecking = false;

  @override
  Future<void> onReady() async {
    super.onReady();
    final preferences = Get.find<SharedPreferences>();
    final seenOnboarding =
        preferences.getBool('zoovana_onboarding_complete_v1') ?? false;
    final check = seenOnboarding
        ? Get.find<SessionRepository>().restore()
        : Future.value(const SessionSignedOut());
    await Future<void>.delayed(const Duration(milliseconds: 1850));
    if (isClosed || Get.currentRoute != AppRoutes.splash) return;
    if (!seenOnboarding) {
      Get.offAllNamed<void>(AppRoutes.onboarding);
      return;
    }
    _route(await check);
  }

  Future<void> retry() async {
    isChecking = true;
    error = null;
    update();
    final check = await Get.find<SessionRepository>().restore();
    isChecking = false;
    update();
    _route(check);
  }

  void _route(SessionCheck check) {
    if (isClosed) return;
    switch (check) {
      case SessionReady(:final session):
        ShellRouter.open(session);
        Get.find<DeepLinkService>().openPending();
      case SessionSignedOut():
        Get.offAllNamed<void>(AppRoutes.auth);
      case SessionUnsupported():
        Get.offAllNamed<void>(AppRoutes.unsupported);
      case SessionUnavailable(error: final failure):
        error = failure.message;
        update();
    }
  }
}
