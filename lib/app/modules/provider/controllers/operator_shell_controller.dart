import 'package:get/get.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../data/models/feeder_models.dart';
import '../../../data/repositories/feeder_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/shell_router.dart';

/// Dashboard, task tabs and On Duty state of the operator shell.
class OperatorShellController extends GetxController {
  OperatorShellController({required this.repository, required this.session});

  final FeederRepository repository;
  final SessionRepository session;

  FeederDashboard? dashboard;
  bool isLoading = true;
  bool isTogglingDuty = false;
  String? error;

  /// Tab shown on the dashboard and on the jobs tab.
  TaskTab dashboardTab = TaskTab.newTasks;
  TaskTab jobsTab = TaskTab.completed;
  final tasks = <TaskTab, List<FeederTask>>{};
  final loadingTabs = <TaskTab>{};
  final tabErrors = <TaskTab, String>{};

  bool get isAvailable =>
      repository.profile?.isAvailable ?? dashboard?.isAvailable ?? false;

  String get greetingName {
    final name = repository.profile?.fullName ?? session.displayName ?? '';
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty
        ? 'Hi there!'.tr
        : 'Hi @name!'.trParams({'name': first});
  }

  /// One or two zone names, else the city, since a long list of zones
  /// doesn't fit the header.
  String get zoneLabel {
    final profile = repository.profile;
    final zones = profile?.zones ?? const [];
    final cities = profile?.cities ?? const [];
    if (zones.isNotEmpty && (zones.length <= 2 || cities.isEmpty)) {
      return zones.map((zone) => zone.name).join(', ');
    }
    return cities.isEmpty ? 'Your zone'.tr : cities.join(' ${'&'.tr} ');
  }

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  /// Re-fetches everything; used on open, pull-to-refresh and notifications.
  Future<void> refreshAll() async {
    error = null;
    update();
    try {
      final results = await Future.wait([
        repository.getDashboard(),
        repository.getProfile(),
      ]);
      dashboard = results.first as FeederDashboard;
    } catch (exception) {
      if (await _rerouteIfNeeded(exception)) return;
      error = AppErrorMapper.map(exception).message;
    }
    isLoading = false;
    update();
    await Future.wait([loadTab(dashboardTab), loadTab(jobsTab)]);
  }

  Future<void> loadTab(TaskTab tab) async {
    loadingTabs.add(tab);
    tabErrors.remove(tab);
    update();
    try {
      tasks[tab] = (await repository.getTasks(tab)).items;
    } catch (exception) {
      if (await _rerouteIfNeeded(exception)) return;
      tabErrors[tab] = AppErrorMapper.map(exception).message;
    }
    loadingTabs.remove(tab);
    update();
  }

  void selectDashboardTab(TaskTab tab) {
    dashboardTab = tab;
    update();
    loadTab(tab);
  }

  void selectJobsTab(TaskTab tab) {
    jobsTab = tab;
    update();
    loadTab(tab);
  }

  Future<void> toggleDuty() async {
    if (isTogglingDuty) return;
    isTogglingDuty = true;
    update();
    try {
      await repository.setAvailability(isAvailable: !isAvailable);
      dashboard = await repository.getDashboard();
    } catch (exception) {
      Get.snackbar('On Duty'.tr, AppErrorMapper.map(exception).message);
    }
    isTogglingDuty = false;
    update();
  }

  /// A 403 here means the operator lost approval: route by the new session.
  Future<bool> _rerouteIfNeeded(Object exception) async {
    final error = AppErrorMapper.map(exception);
    final lostAccess =
        error.hasCode(ApiErrorCode.feederProfileNotApproved) ||
        error.hasCode(ApiErrorCode.feederProfileMissing) ||
        error.hasCode(ApiErrorCode.insufficientRole);
    if (!lostAccess) return false;
    try {
      ShellRouter.open(await session.reload());
    } catch (_) {
      return false;
    }
    return true;
  }
}
