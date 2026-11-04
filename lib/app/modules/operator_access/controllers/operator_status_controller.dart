import 'package:get/get.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../data/models/charity_session.dart';
import '../../../data/models/feeder_models.dart';
import '../../../data/repositories/feeder_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/shell_router.dart';

/// Under review, rejected and suspended operators wait here.
class OperatorStatusController extends GetxController {
  OperatorStatusController({required this.feeder, required this.session});

  final FeederRepository feeder;
  final SessionRepository session;

  FeederProfile? profile;
  bool isLoading = true;
  bool isChecking = false;
  String? error;

  VerificationStatus get status =>
      profile?.verificationStatus ??
      session.current?.verificationStatus ??
      VerificationStatus.pendingReview;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading = profile == null;
    error = null;
    update();
    try {
      profile = await feeder.getProfile();
    } catch (exception) {
      final mapped = AppErrorMapper.map(exception);
      if (mapped.hasCode(ApiErrorCode.feederProfileMissing)) {
        Get.offAllNamed<void>(AppRoutes.operatorApply);
        return;
      }
      error = mapped.message;
    }
    isLoading = false;
    update();
  }

  /// Re-reads the session; moves to the operator shell once approved.
  Future<void> checkAgain() async {
    isChecking = true;
    update();
    try {
      final current = await session.reload();
      if (ShellRouter.routeFor(current) != AppRoutes.operatorStatus) {
        ShellRouter.open(current);
        return;
      }
      await load();
    } catch (exception) {
      error = AppErrorMapper.map(exception).message;
    }
    isChecking = false;
    update();
  }
}
