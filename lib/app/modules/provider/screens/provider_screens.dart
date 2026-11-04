import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/assets/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/models/feeder_models.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/shell_router.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../home/screens/customer_shell_screen.dart';
import '../controllers/operator_payouts_controller.dart';
import '../controllers/operator_shell_controller.dart';
import '../controllers/operator_task_controller.dart';

/// Tag colours per assignment status.
(Color, Color) _statusColors(TaskStatus status) => switch (status) {
  TaskStatus.pendingAcceptance => (AppColors.accent, const Color(0xFFFDECEC)),
  TaskStatus.accepted ||
  TaskStatus.purchasing => (const Color(0xFF8E7CC3), const Color(0xFFEEEAF8)),
  TaskStatus.feeding => (const Color(0xFFF2B90F), const Color(0xFFFFF4D2)),
  TaskStatus.proofSubmitted => (AppColors.brand, const Color(0xFFD9F0EF)),
  TaskStatus.proofRejected => (AppColors.accent, AppColors.accentSoft),
  TaskStatus.completed => (const Color(0xFF2BB673), const Color(0xFFDDF5E8)),
  _ => (AppColors.textSecondary, AppColors.surfaceMuted),
};

Widget _statusTag(TaskStatus status, {String? label}) {
  final (foreground, background) = _statusColors(status);
  return StatusTag(
    label: label ?? status.label,
    foreground: foreground,
    background: background,
  );
}

/// `02:23` style time left until [deadline], or null once it has passed.
String? _timeLeft(DateTime? deadline) {
  if (deadline == null) return null;
  final left = deadline.difference(DateTime.now());
  if (left.isNegative) return null;
  final hours = left.inHours.toString().padLeft(2, '0');
  final minutes = (left.inMinutes % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}

/// Operator shell with the Home, Jobs and Profile destinations.
class ProviderShellScreen extends StatefulWidget {
  const ProviderShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ProviderShellScreen> createState() => _ProviderShellScreenState();
}

class _ProviderShellScreenState extends State<ProviderShellScreen> {
  late int _index = Get.arguments is int
      ? Get.arguments as int
      : widget.initialIndex;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: IndexedStack(
      index: _index,
      children: [
        _ProviderDashboard(active: _index == 0),
        _JobsTab(active: _index == 1),
        _ProviderProfile(active: _index == 2),
      ],
    ),
    bottomNavigationBar: AppBottomNav(
      destinations: ProviderNav.destinations,
      selectedIndex: _index,
      onSelected: (index) {
        setState(() => _index = index);
        Get.find<OperatorShellController>().refreshAll();
      },
    ),
  );
}

class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderShellScreen(initialIndex: 1);
}

List<Widget> _providerActions() => [
  NotificationBell(
    onReturn: () => Get.find<OperatorShellController>().refreshAll(),
  ),
];

Widget _fadeSlide(Widget child, Animation<double> animation) => FadeTransition(
  opacity: animation,
  child: SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, .04),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  ),
);

Future<void> _openTask(FeederTask task) async {
  await Get.toNamed<void>(AppRoutes.providerJobDetails, arguments: task);
  Get.find<OperatorShellController>().refreshAll();
}

class _ProviderDashboard extends StatelessWidget {
  const _ProviderDashboard({required this.active});

  /// Replays the sections' entrance each time the tab is shown.
  final bool active;

  static const _tabs = [TaskTab.newTasks, TaskTab.active, TaskTab.completed];

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorShellController>(
    builder: (controller) {
      final summary = controller.dashboard;
      final tab = controller.dashboardTab;
      final tasks = controller.tasks[tab] ?? const <FeederTask>[];
      return ColoredBox(
        color: AppColors.brand,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: controller.refreshAll,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: BrandHeader(
                  bottomPadding: 26,
                  actions: _providerActions(),
                  child: HeaderGreeting(
                    greeting: controller.greetingName,
                    location: controller.zoneLabel,
                    locationSize: 19,
                  ),
                ),
              ),
              // Fills the rest of the screen, so the teal background doesn't
              // show below a short task list.
              SliverFillRemaining(
                hasScrollBody: false,
                child: RoundedSheet(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      19,
                      14,
                      19,
                      AppBottomNav.contentPadding(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: staggered(trigger: active, [
                        Text(
                          'Your Overview'.tr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: _OverviewStat(
                                label: 'New Tasks'.tr,
                                tint: AppColors.brand,
                                value: summary?.newTasks ?? 0,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _OverviewStat(
                                label: 'Active Tasks'.tr,
                                tint: const Color(0xFFE9B21B),
                                value: summary?.activeTasks ?? 0,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _OverviewStat(
                                label: 'Completed'.tr,
                                icon: Iconsax.tick_circle_copy,
                                tint: const Color(0xFF2BB673),
                                value: summary?.completedTasks ?? 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        SurfaceCard(
                          radius: 8,
                          onTap: () =>
                              Get.toNamed<void>(AppRoutes.providerPayouts),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF8B5CF6),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Eligible payouts'.tr,
                                  style: const TextStyle(fontSize: 14.5),
                                ),
                              ),
                              Text(
                                summary?.eligiblePayoutLabel ?? '0',
                                style: const TextStyle(
                                  color: AppColors.brand,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Tasks :'.tr,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              'On Duty :'.tr,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            _DutySwitch(
                              value: controller.isAvailable,
                              busy: controller.isTogglingDuty,
                              onChanged: (_) => controller.toggleDuty(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FilterPills(
                          expand: true,
                          labels: [
                            'New (@count)'.trParams({
                              'count': '${summary?.newTasks ?? 0}',
                            }),
                            'Active (@count)'.trParams({
                              'count': '${summary?.activeTasks ?? 0}',
                            }),
                            'Done (@count)'.trParams({
                              'count': '${summary?.completedTasks ?? 0}',
                            }),
                          ],
                          selected: _tabs.indexOf(tab),
                          onSelected: (index) =>
                              controller.selectDashboardTab(_tabs[index]),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: AppMotion.medium,
                          switchInCurve: AppMotion.curve,
                          switchOutCurve: AppMotion.curve,
                          layoutBuilder: pinnedSwitcherLayout,
                          child: _TaskList(
                            key: ValueKey(tab),
                            tasks: tasks,
                            isLoading: controller.loadingTabs.contains(tab),
                            error:
                                controller.tabErrors[tab] ?? controller.error,
                            empty: switch (tab) {
                              TaskTab.newTasks =>
                                controller.isAvailable
                                    ? 'No new tasks right now.'.tr
                                    : 'Turn on On Duty to get new tasks.'.tr,
                              TaskTab.active => 'No tasks in progress.'.tr,
                              _ => 'No completed tasks yet.'.tr,
                            },
                            onRetry: () => controller.loadTab(tab),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.empty,
    required this.onRetry,
    this.error,
  });

  final List<FeederTask> tasks;
  final bool isLoading;
  final String? error;
  final String empty;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty && isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      );
    }
    if (tasks.isEmpty && error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            TextButton(onPressed: onRetry, child: Text('Try again'.tr)),
          ],
        ),
      );
    }
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 48),
        child: Center(
          child: Text(
            empty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final task in tasks) ...[
          _JobCard(task: task),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.tint,
    required this.value,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color tint;
  final int value;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 8,
    padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$value',
              style: const TextStyle(color: AppColors.accent, fontSize: 20),
            ),
            const Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: icon == null
                    ? AssetIcon(AppIcons.orderScroll, size: 16, color: tint)
                    : Icon(icon, size: 16, color: tint),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5),
        ),
      ],
    ),
  );
}

class _DutySwitch extends StatelessWidget {
  const _DutySwitch({
    required this.value,
    required this.onChanged,
    this.busy = false,
  });
  final bool value;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: 'On duty'.tr,
    child: AppPressable(
      pressedScale: .94,
      child: GestureDetector(
        onTap: busy ? null : () => onChanged(!value),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.curve,
          width: 36,
          height: 20,
          padding: const EdgeInsets.all(2),
          alignment: value
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: value ? AppColors.accent : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: AppColors.accent,
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}

class _JobsTab extends StatelessWidget {
  const _JobsTab({required this.active});

  final bool active;

  static const _tabs = [TaskTab.completed, TaskTab.active, TaskTab.closed];

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorShellController>(
    builder: (controller) {
      final tab = controller.jobsTab;
      return Column(
        children: [
          BrandHeader(actions: _providerActions()),
          Expanded(
            child: ColoredBox(
              color: const Color(0xFFFDFDFD),
              child: RefreshIndicator(
                color: AppColors.brand,
                onRefresh: () => controller.loadTab(tab),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    30,
                    20,
                    AppBottomNav.contentPadding(context),
                  ),
                  children: staggered(trigger: active, [
                    Text(
                      'Jobs History :'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilterPills(
                      expand: true,
                      height: 34,
                      labels: [for (final item in _tabs) item.label],
                      selected: _tabs.indexOf(tab),
                      onSelected: (index) =>
                          controller.selectJobsTab(_tabs[index]),
                    ),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.curve,
                      switchOutCurve: AppMotion.curve,
                      layoutBuilder: pinnedSwitcherLayout,
                      child: _TaskList(
                        key: ValueKey(tab),
                        tasks: controller.tasks[tab] ?? const [],
                        isLoading: controller.loadingTabs.contains(tab),
                        error: controller.tabErrors[tab],
                        empty: 'No jobs here yet.'.tr,
                        onRetry: () => controller.loadTab(tab),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.task});
  final FeederTask task;

  @override
  Widget build(BuildContext context) {
    final deadline = task.status == TaskStatus.pendingAcceptance
        ? _timeLeft(task.acceptDeadlineAt)
        : null;
    final primary = switch (task.status) {
      TaskStatus.pendingAcceptance when task.can(TaskAction.accept) =>
        'Accept'.tr,
      TaskStatus.proofRejected => 'Fix proof'.tr,
      _ when task.allowedActions.isNotEmpty => 'Continue'.tr,
      _ => null,
    };
    return SurfaceCard(
      shadow: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 13, 10),
            child: Column(
              children: [
                SizedBox(
                  height: 24,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.programName.isEmpty
                              ? task.packageName
                              : task.programName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15.5),
                        ),
                      ),
                      _statusTag(
                        task.status,
                        label: deadline == null
                            ? null
                            : 'Accept in @time'.trParams({'time': deadline}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                _JobLine(
                  icon: Iconsax.receipt_2_copy,
                  text: [
                    task.requestReference,
                    '@count meals'.trParams({'count': '${task.mealCount}'}),
                    task.foodLabel,
                  ].join(' · '),
                ),
                const SizedBox(height: 9),
                _JobLine(
                  icon: Iconsax.location_copy,
                  text: [
                    task.zoneName,
                    task.cityName,
                  ].where((part) => part.isNotEmpty).join(', '),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 13, 14),
            child: Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'View Details'.tr,
                    height: 40,
                    fontSize: 15,
                    style: PillButtonStyle.muted,
                    onPressed: () => _openTask(task),
                  ),
                ),
                if (primary != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: PillButton(
                      label: primary,
                      height: 40,
                      fontSize: 15,
                      shadow: true,
                      fontWeight: FontWeight.w500,
                      onPressed: () => _openTask(task),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey outline icon followed by a detail, as in the job cards.
class _JobLine extends StatelessWidget {
  const _JobLine({required this.icon, required this.text, this.size = 14.5});
  final IconData icon;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    child: Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF555B61)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: size, color: const Color(0xFF555B61)),
          ),
        ),
      ],
    ),
  );
}

class _ProviderProfile extends StatelessWidget {
  const _ProviderProfile({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorShellController>(
    builder: (controller) => ColoredBox(
      color: AppColors.brand,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: BrandHeader(
              bottomPadding: 22,
              actions: _providerActions(),
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operator Profile'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Duty status, jobs, payouts & account'.tr,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: RoundedSheet(
              child: ProfileMenu(
                active: active,
                isProvider: true,
                onOpen: (route, label) async {
                  await Get.toNamed<dynamic>(route, arguments: label);
                  controller.refreshAll();
                },
                extraItems: const [
                  // Out of charity scope: the app picks the donor or operator
                  // shell from the signed-in role, so there is no mode switch.
                  ProfileMenuItem(
                    label: 'Sign out',
                    icon: Icons.logout_rounded,
                    isDestructive: true,
                    onTap: ShellRouter.signOut,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One task: overview, field steps and proof. Buttons come only from
/// `allowed_actions`.
class ProviderJobDetailsScreen extends StatelessWidget {
  const ProviderJobDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorTaskController>(
    builder: (controller) {
      final task = controller.task;
      if (controller.showAccepted && task != null) {
        return SuccessView(
          title: 'Task Accepted'.tr,
          message:
              'Buy the food for this round, then feed the animals in @zone.'
                  .trParams({
                    'zone': task.zoneName.isEmpty
                        ? 'your zone'.tr
                        : task.zoneName,
                  }),
          actions: [
            PillButton(label: 'View Task'.tr, onPressed: controller.openTask),
            PillButton(
              label: 'Back to homepage'.tr,
              style: PillButtonStyle.muted,
              onPressed: () => Get.offAllNamed<void>(AppRoutes.providerHome),
            ),
          ],
        );
      }
      return Scaffold(
        appBar: ZoovanaAppBar(title: 'Task Details'.tr),
        bottomNavigationBar: task == null
            ? null
            : _actions(context, controller, task),
        body: AppStateView(
          isLoading: controller.isLoading,
          error: task == null ? controller.error : null,
          onRetry: controller.load,
          child: task == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  color: AppColors.brand,
                  onRefresh: controller.load,
                  child: _TaskBody(controller: controller, task: task),
                ),
        ),
      );
    },
  );

  static Widget? _actions(
    BuildContext context,
    OperatorTaskController controller,
    FeederTask task,
  ) {
    final busy = controller.busyAction;
    PillButton button(
      String label,
      String action,
      VoidCallback onPressed, {
      bool muted = false,
    }) => PillButton(
      label: label,
      style: muted ? PillButtonStyle.muted : PillButtonStyle.primary,
      isLoading: busy == action,
      onPressed: busy == null ? onPressed : null,
    );

    final children = <Widget>[
      if (task.can(TaskAction.decline))
        button(
          'Decline'.tr,
          TaskAction.decline,
          () => _decline(context, controller),
          muted: true,
        ),
      if (task.can(TaskAction.accept))
        button('Accept Task'.tr, TaskAction.accept, controller.accept),
      if (task.can(TaskAction.purchasing))
        button(
          'Start buying'.tr,
          TaskAction.purchasing,
          controller.startPurchasing,
        ),
      if (task.status == TaskStatus.purchasing &&
          task.can(TaskAction.feeding)) ...[
        if (!controller.onTheWay)
          PillButton(
            label: 'Mark As bought'.tr,
            onPressed: controller.markOnTheWay,
          )
        else
          button(
            'Start feeding'.tr,
            TaskAction.feeding,
            controller.startFeeding,
          ),
      ],
      if (task.status == TaskStatus.proofRejected &&
          task.can(TaskAction.feeding))
        button(
          'Redo feeding'.tr,
          TaskAction.feeding,
          controller.startFeeding,
          muted: true,
        ),
      if (task.can(TaskAction.submitProof))
        button(
          'Submit proof'.tr,
          TaskAction.submitProof,
          controller.submitProof,
        ),
    ];
    return children.isEmpty ? null : BottomActionBar(children: children);
  }

  static Future<void> _decline(
    BuildContext context,
    OperatorTaskController controller,
  ) async {
    final reason = TextEditingController(
      text: 'Unavailable during the required period'.tr,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline this task?'.tr),
        content: TextField(
          controller: reason,
          maxLines: 3,
          inputFormatters: [LengthLimitingTextInputFormatter(300)],
          decoration: InputDecoration(labelText: 'Reason'.tr),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep it'.tr),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Decline'.tr),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (confirmed ?? false) await controller.decline(text);
  }
}

class _TaskBody extends StatelessWidget {
  const _TaskBody({required this.controller, required this.task});
  final OperatorTaskController controller;
  final FeederTask task;

  /// Field step shown in the progress bar: buy, on the way, feed, review.
  int get _step => switch (task.status) {
    TaskStatus.accepted => 1,
    TaskStatus.purchasing => controller.onTheWay ? 2 : 1,
    TaskStatus.feeding || TaskStatus.proofRejected => 3,
    TaskStatus.proofSubmitted || TaskStatus.completed => 4,
    _ => 0,
  };

  static const _stepLabels = [
    '',
    'Buy food',
    'On the way',
    'Feeding',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    final step = _step;
    final collecting = task.can(TaskAction.uploadMedia);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: staggered([
        Row(
          children: [
            Expanded(
              child: Text(
                task.programName.isEmpty ? task.packageName : task.programName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (task.status == TaskStatus.pendingAcceptance)
              _Countdown(deadline: task.acceptDeadlineAt)
            else
              _statusTag(
                task.status,
                label:
                    task.status == TaskStatus.purchasing && controller.onTheWay
                    ? 'On the way'.tr
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        _JobLine(
          icon: Iconsax.receipt_2_copy,
          text: 'Request @reference'.trParams({
            'reference': task.requestReference,
          }),
          size: 13.5,
        ),
        if (step > 0) ...[
          const SizedBox(height: 14),
          Transform.translate(
            offset: const Offset(-1, 0),
            child: Bleed(
              amount: 4,
              child: StepProgress(
                step: step,
                total: 4,
                label: _stepLabels[step].tr,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 14),
        if (task.status == TaskStatus.proofRejected)
          _Notice(
            icon: Icons.error_outline_rounded,
            color: AppColors.accent,
            text:
                task.proofRejectionReason ??
                'The reviewer asked for changes to the proof.'.tr,
          ),
        if (task.status == TaskStatus.proofSubmitted)
          _Notice(
            icon: Iconsax.clock_copy,
            color: AppColors.brand,
            text:
                'Under review. A reviewer checks the proof and completes the '
                        'task.'
                    .tr,
          ),
        if (task.status.isClosed && task.status != TaskStatus.completed)
          _Notice(
            icon: Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            text: switch (task.status) {
              TaskStatus.declined => 'This task is declined.'.tr,
              TaskStatus.expired => 'This task is expired.'.tr,
              TaskStatus.reassigned => 'This task is reassigned.'.tr,
              _ => 'This task is cancelled.'.tr,
            },
          ),
        AnimatedSwitcher(
          duration: AppMotion.slow,
          switchInCurve: AppMotion.curve,
          switchOutCurve: AppMotion.curve,
          layoutBuilder: pinnedSwitcherLayout,
          transitionBuilder: _fadeSlide,
          child: KeyedSubtree(
            key: ValueKey((task.status, controller.onTheWay)),
            child: collecting
                ? _ProofForm(controller: controller, task: task)
                : _TaskOverview(task: task, onTheWay: controller.onTheWay),
          ),
        ),
      ]),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Ticking "Accept in hh:mm" tag; shows "Expired" once the deadline passes.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.deadline});
  final DateTime? deadline;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = _timeLeft(widget.deadline);
    return StatusTag(
      label: left == null
          ? 'Expired'.tr
          : 'Accept in @time'.trParams({'time': left}),
      foreground: AppColors.accent,
      background: Colors.white,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 4),
      ],
      Flexible(
        child: Text(
          text,
          style: TextStyle(
            fontSize: icon == null ? 19 : 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

/// Zone, shopping target and instructions. The map and checklist appear only
/// once the API sends `feeding_location` and `purchase_requirements`.
class _TaskOverview extends StatelessWidget {
  const _TaskOverview({required this.task, required this.onTheWay});
  final FeederTask task;
  final bool onTheWay;

  @override
  Widget build(BuildContext context) {
    final location = task.feedingLocation;
    final requirements = task.purchaseRequirements;
    final zone = [
      task.zoneName,
      task.cityName,
    ].where((part) => part.isNotEmpty).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          onTheWay ? 'Feeding location :'.tr : 'Feeding zone :'.tr,
          icon: Iconsax.location_copy,
        ),
        const SizedBox(height: 14),
        if (location != null) ...[
          const _MapCard(height: 158),
          const SizedBox(height: 9),
        ],
        _JobLine(
          icon: Iconsax.location_copy,
          text: location?['label']?.toString() ?? zone,
          size: 15,
        ),
        const SizedBox(height: 15),
        _Box(
          icon: Iconsax.bag_2_copy,
          title: 'Shopping target'.tr,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            children: [
              _ValueLine(label: 'Package'.tr, value: task.packageName),
              _ValueLine(label: 'Meals'.tr, value: '${task.mealCount}'),
              _ValueLine(label: 'Food quantity'.tr, value: task.foodLabel),
              _ValueLine(label: 'Food budget'.tr, value: task.foodBudgetLabel),
              _ValueLine(label: 'Your fee'.tr, value: task.feederFeeLabel),
            ],
          ),
        ),
        if (requirements.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Box(
            icon: Iconsax.task_square_copy,
            title: 'Buy Items'.tr,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                for (final item in requirements)
                  _ValueLine(
                    label: '${item['name'] ?? item['name_en'] ?? 'Item'.tr}',
                    value: '${item['quantity'] ?? ''} ${item['unit'] ?? ''}'
                        .trim(),
                  ),
              ],
            ),
          ),
        ],
        if (task.instructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Box(
            icon: Iconsax.note_text_copy,
            title: 'Instructions'.tr,
            padding: const EdgeInsets.fromLTRB(12, 15, 12, 18),
            child: Text(
              task.instructions,
              style: const TextStyle(fontSize: 14, height: 1.25),
            ),
          ),
        ],
        if (task.latestProof != null && task.latestProof!.media.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('Submitted proof :'.tr),
          const SizedBox(height: 12),
          _MediaGrid(media: task.latestProof!.media),
        ],
      ],
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

/// Photos, videos and receipt with previews, remove and retry; plus the
/// numbers and note for the proof.
class _ProofForm extends StatelessWidget {
  const _ProofForm({required this.controller, required this.task});
  final OperatorTaskController controller;
  final FeederTask task;

  Future<void> _pick(BuildContext context, {bool receipt = false}) async {
    final picked = await pickMedia(context, allowVideo: !receipt);
    if (picked == null) return;
    await controller.addFile(
      picked.path,
      receipt
          ? TaskMediaType.receipt
          : picked.isVideo
          ? TaskMediaType.video
          : TaskMediaType.image,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previous = task.previousProof;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Feed the animals'.tr),
        const SizedBox(height: 8),
        Text(
          [
            'Zone: @zone'.trParams({
              'zone': task.zoneName.isEmpty ? task.cityName : task.zoneName,
            }),
            '@count meals'.trParams({'count': '${task.mealCount}'}),
            task.foodLabel,
          ].join(' · '),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        AppPressable(
          child: GestureDetector(
            onTap: () => _pick(context),
            child: CustomPaint(
              painter: const _DashedBorderPainter(),
              child: Container(
                height: 92,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.camera_copy,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Upload images / Videos for animals feeding'.tr,
                      style: const TextStyle(fontSize: 15.5),
                    ),
                    Text(
                      '@count / @max files'.trParams({
                        'count': '${controller.fileCount}',
                        'max': '${OperatorTaskController.maxFiles}',
                      }),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _UploadGrid(controller: controller),
        if (previous != null && previous.media.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Rejected proof'.tr,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _MediaGrid(media: previous.media),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: LabeledField(
                label: 'Meals served'.tr,
                controller: controller.mealsController,
                compact: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: LabeledField(
                label: 'Animals fed (approx.)'.tr,
                controller: controller.animalsController,
                compact: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LabeledField(
                label: 'Receipt amount (@currency)'.trParams({
                  'currency': task.currency,
                }),
                controller: controller.receiptController,
                compact: true,
                required: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: PillButton(
                label: 'Add receipt'.tr,
                height: 44,
                style: PillButtonStyle.muted,
                onPressed: () => _pick(context, receipt: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionTitle('Notes for the donor'.tr),
        const SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: TextField(
            controller: controller.noteController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Enter Notes....'.tr,
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFFA3A3A3),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
              border: _notesBorder,
              enabledBorder: _notesBorder,
              focusedBorder: _notesBorder.copyWith(
                borderSide: const BorderSide(color: AppColors.brand),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your location is read when you submit, so submit at the feeding spot.'
              .tr,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        if (controller.proofError != null) ...[
          const SizedBox(height: 10),
          Text(
            controller.proofError!,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  static final _notesBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.fieldBorder),
  );
}

class _UploadGrid extends StatelessWidget {
  const _UploadGrid({required this.controller});
  final OperatorTaskController controller;

  @override
  Widget build(BuildContext context) {
    final uploaded = controller.pendingMedia;
    final active = controller.activeUploads;
    if (uploaded.isEmpty && active.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final media in uploaded)
          _Thumb(
            source: media.thumbnailUrl ?? media.url,
            isVideo: media.type == TaskMediaType.video,
            badge: media.type == TaskMediaType.receipt ? 'Receipt'.tr : null,
            onRemove: controller.task?.can(TaskAction.deleteMedia) ?? false
                ? () => controller.removeMedia(media)
                : null,
          ),
        for (final upload in active)
          _Thumb(
            source: upload.path,
            isVideo: upload.type == TaskMediaType.video,
            isUploading: upload.isUploading,
            error: upload.error,
            onRetry: () => controller.retry(upload),
            onRemove: () => controller.discard(upload),
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.source,
    this.isVideo = false,
    this.isUploading = false,
    this.badge,
    this.error,
    this.onRetry,
    this.onRemove,
  });

  final String source;
  final bool isVideo;
  final bool isUploading;
  final String? badge;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 96,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          LocalOrNetworkImage(source, isVideo: isVideo),
          if (isUploading)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (error != null)
            ColoredBox(
              color: const Color(0xB3000000),
              child: InkWell(
                onTap: onRetry,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      Text(
                        error!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (badge != null)
            PositionedDirectional(
              start: 4,
              bottom: 4,
              child: StatusTag(
                label: badge!,
                foreground: Colors.white,
                background: const Color(0x99000000),
              ),
            ),
          if (onRemove != null && !isUploading)
            PositionedDirectional(
              top: 2,
              end: 2,
              child: IconButton(
                tooltip: 'Remove'.tr,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x99000000),
                ),
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.media});
  final List<TaskMedia> media;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final item in media)
        _Thumb(
          source: item.thumbnailUrl ?? item.url,
          isVideo: item.type == TaskMediaType.video,
          badge: item.type == TaskMediaType.receipt ? 'Receipt'.tr : null,
        ),
    ],
  );
}

/// Static map placeholder until the API sends coordinates to draw.
class _MapCard extends StatelessWidget {
  const _MapCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.providerMap, fit: BoxFit.cover),
          const Align(
            alignment: Alignment(-.05, -.15),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.accent,
              child: Icon(Iconsax.location_copy, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Box extends StatelessWidget {
  const _Box({
    required this.icon,
    required this.title,
    required this.child,
    required this.padding,
  });
  final IconData icon;
  final String title;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 10,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 49,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accent, size: 21),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.fieldBorder),
        Padding(padding: padding, child: child),
      ],
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 9) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Read-only payouts: eligible, approved, paid or cancelled.
class OperatorPayoutsScreen extends StatelessWidget {
  const OperatorPayoutsScreen({super.key});

  static const _filters = <PayoutStatus?>[
    null,
    PayoutStatus.eligible,
    PayoutStatus.approved,
    PayoutStatus.paid,
  ];

  @override
  Widget build(BuildContext context) => GetBuilder<OperatorPayoutsController>(
    builder: (controller) => Scaffold(
      appBar: ZoovanaAppBar(title: 'Payouts'.tr),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: FilterPills(
              expand: true,
              labels: [
                'All'.tr,
                for (final status in _filters.skip(1)) status!.label,
              ],
              selected: _filters.indexOf(controller.filter),
              onSelected: (index) => controller.select(_filters[index]),
            ),
          ),
          if (controller.totals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                children: [
                  for (final (index, entry)
                      in controller.totals.entries.indexed) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: SurfaceCard(
                        radius: 8,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              PayoutStatus.fromCode(entry.key) ==
                                      PayoutStatus.unknown
                                  ? entry.key
                                  : PayoutStatus.fromCode(entry.key).label,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: AppStateView(
              isLoading: controller.isLoading,
              error: controller.error,
              onRetry: controller.load,
              child: controller.payouts.isEmpty
                  ? Center(
                      child: Text(
                        'No payouts yet.'.tr,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.brand,
                      onRefresh: controller.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        itemCount: controller.payouts.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _PayoutCard(payout: controller.payouts[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout});
  final FeederPayout payout;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (payout.status) {
      PayoutStatus.eligible => (
        'Eligible'.tr,
        AppColors.brand,
        const Color(0xFFD9F0EF),
      ),
      PayoutStatus.approved => (
        'Approved'.tr,
        const Color(0xFF8E7CC3),
        const Color(0xFFEEEAF8),
      ),
      PayoutStatus.paid => (
        'Paid'.tr,
        const Color(0xFF2BB673),
        const Color(0xFFDDF5E8),
      ),
      PayoutStatus.cancelled => (
        'Cancelled'.tr,
        AppColors.accent,
        AppColors.accentSoft,
      ),
      PayoutStatus.unknown => (
        'Updating'.tr,
        AppColors.textSecondary,
        AppColors.surfaceMuted,
      ),
    };
    final date = payout.paidAt ?? payout.eligibleAt;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payout.amountLabel,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    payout.requestReference,
                    if (date != null) '${date.day}/${date.month}/${date.year}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          StatusTag(
            label: label,
            foreground: foreground,
            background: background,
          ),
        ],
      ),
    );
  }
}
