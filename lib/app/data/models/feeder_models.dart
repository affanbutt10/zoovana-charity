import 'package:get/get.dart';

import '../../../apis/core/api_response.dart';
import '../../core/services/app_locale.dart';
import 'charity_package.dart';
import 'charity_session.dart';

/// Assignment status of an operator task. These are not request statuses: a
/// new task is `pending_acceptance` while the donor sees `assigned`.
enum TaskStatus {
  pendingAcceptance('pending_acceptance', 'New'),
  accepted('accepted', 'Accepted'),
  purchasing('purchasing', 'Buying food'),
  feeding('feeding', 'Feeding'),
  proofSubmitted('proof_submitted', 'Under review'),
  proofRejected('proof_rejected', 'Needs changes'),
  completed('completed', 'Completed'),
  declined('declined', 'Declined'),
  expired('expired', 'Expired'),
  reassigned('reassigned', 'Reassigned'),
  cancelled('cancelled', 'Cancelled'),
  unknown('unknown', 'Updating');

  const TaskStatus(this.code, this._label);

  final String code;
  final String _label;

  /// Translated display text.
  String get label => _label.tr;

  /// Closed tasks are shown read-only.
  bool get isClosed => const {
    completed,
    declined,
    expired,
    reassigned,
    cancelled,
  }.contains(this);

  static TaskStatus fromCode(String? code) =>
      values.firstWhere((status) => status.code == code, orElse: () => unknown);
}

/// Values of a task's `allowed_actions`. Buttons come only from these.
abstract final class TaskAction {
  static const accept = 'accept';
  static const decline = 'decline';
  static const purchasing = 'purchasing';
  static const feeding = 'feeding';
  static const uploadMedia = 'upload_media';
  static const deleteMedia = 'delete_media';
  static const submitProof = 'submit_proof';
}

/// Task tabs and the statuses each one lists.
enum TaskTab {
  newTasks('New', ['pending_acceptance']),
  active('Active', [
    'accepted',
    'purchasing',
    'feeding',
    'proof_submitted',
    'proof_rejected',
  ]),
  completed('Completed', ['completed']),
  closed('Closed', ['declined', 'expired', 'reassigned', 'cancelled']);

  const TaskTab(this._label, this.statuses);

  final String _label;
  final List<String> statuses;

  /// Translated display text.
  String get label => _label.tr;
}

enum TaskMediaType {
  image,
  video,
  receipt;

  static TaskMediaType fromCode(String? code) =>
      values.firstWhere((type) => type.name == code, orElse: () => image);
}

class TaskMedia {
  const TaskMedia({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.expiresAt,
    this.capturedAt,
  });

  final String id;
  final TaskMediaType type;

  /// HTTPS URL, or a local file path for seed uploads.
  final String url;
  final String? thumbnailUrl;
  final DateTime? expiresAt;
  final DateTime? capturedAt;

  factory TaskMedia.fromJson(Map<String, dynamic> json) => TaskMedia(
    id: json.str('id'),
    type: TaskMediaType.fromCode(json.strOrNull('media_type')),
    url: json.str('url'),
    thumbnailUrl: json.strOrNull('thumbnail_url'),
    expiresAt: json.time('expires_at'),
    capturedAt: json.time('captured_at'),
  );
}

class TaskProof {
  const TaskProof({
    required this.id,
    required this.reviewStatus,
    this.media = const [],
    this.rejectionReason,
  });

  final String id;
  final String reviewStatus;
  final List<TaskMedia> media;
  final String? rejectionReason;

  factory TaskProof.fromJson(Map<String, dynamic> json) => TaskProof(
    id: json.str('id'),
    reviewStatus: json.str('review_status'),
    media: [for (final item in json.objects('media')) TaskMedia.fromJson(item)],
    rejectionReason: json.strOrNull('rejection_reason'),
  );
}

class TaskEvent {
  const TaskEvent({required this.status, required this.at});

  final TaskStatus status;
  final DateTime at;
}

/// An operator's assignment. The list, the detail and every action return
/// this shape; replace the local copy with each response.
class FeederTask {
  const FeederTask({
    required this.id,
    required this.requestReference,
    required this.status,
    required this.programName,
    required this.cityName,
    required this.packageName,
    required this.mealCount,
    required this.foodQuantityGrams,
    required this.foodBudget,
    required this.feederFee,
    required this.currency,
    required this.zoneName,
    this.requestId = '',
    this.instructions = '',
    this.assignedAt,
    this.acceptDeadlineAt,
    this.expectedCompletionAt,
    this.completedAt,
    this.allowedActions = const {},
    this.timeline = const [],
    this.pendingMedia = const [],
    this.latestProof,
    this.previousProof,
    this.proofRejectionReason,
    this.canResubmit = false,
    this.feedingLocation,
    this.purchaseRequirements = const [],
  });

  final String id;
  final String requestId;
  final String requestReference;
  final TaskStatus status;
  final String programName;
  final String cityName;
  final String packageName;
  final int mealCount;
  final int foodQuantityGrams;

  /// Money strings, e.g. `"60.00"`.
  final String foodBudget;
  final String feederFee;
  final String currency;
  final String zoneName;
  final String instructions;
  final DateTime? assignedAt;
  final DateTime? acceptDeadlineAt;
  final DateTime? expectedCompletionAt;
  final DateTime? completedAt;
  final Set<String> allowedActions;
  final List<TaskEvent> timeline;

  /// Uploaded but not yet attached to a submitted proof.
  final List<TaskMedia> pendingMedia;
  final TaskProof? latestProof;
  final TaskProof? previousProof;
  final String? proofRejectionReason;
  final bool canResubmit;

  /// Not sent yet (always null). Shown as a map once filled.
  final Map<String, dynamic>? feedingLocation;

  /// Not sent yet (always empty). Shown as a checklist once filled.
  final List<Map<String, dynamic>> purchaseRequirements;

  bool can(String action) => allowedActions.contains(action);

  String get foodBudgetLabel => formatMoney(foodBudget, currency);
  String get feederFeeLabel => formatMoney(feederFee, currency);

  String get foodLabel {
    if (foodQuantityGrams < 1000) {
      return '@grams g'.trParams({'grams': '$foodQuantityGrams'});
    }
    final kg = foodQuantityGrams / 1000;
    return '@kg kg'.trParams({
      'kg': kg == kg.roundToDouble()
          ? kg.toStringAsFixed(0)
          : kg.toStringAsFixed(1),
    });
  }

  factory FeederTask.fromJson(Map<String, dynamic> json) {
    final program = json.object('program');
    final package = json.object('package');
    final zone = json.object('zone');
    return FeederTask(
      id: json.str('id'),
      requestId: json.str('request_id'),
      requestReference: json.str('request_reference'),
      status: TaskStatus.fromCode(json.strOrNull('status')),
      programName: json.str('program_name'),
      cityName: AppLocale.pick(
        program?.strOrNull('city_name_en'),
        program?.strOrNull('city_name_ar'),
        program?.strOrNull('city_name_ur'),
      ),
      packageName: package == null
          ? json.str('package_name')
          : AppLocale.pick(
              package.strOrNull('name_en') ?? json.strOrNull('package_name'),
              package.strOrNull('name_ar'),
              package.strOrNull('name_ur'),
            ),
      mealCount: json.integer('meal_count'),
      foodQuantityGrams: json.integer('food_quantity_grams'),
      foodBudget: json.str('food_budget', '0.00'),
      feederFee: json.str('feeder_fee', '0.00'),
      currency: json.str('currency', 'SAR'),
      zoneName: zone == null
          ? ''
          : AppLocale.pick(
              zone.strOrNull('name_en'),
              zone.strOrNull('name_ar'),
              zone.strOrNull('name_ur'),
            ),
      instructions: json.str('instructions'),
      assignedAt: json.time('assigned_at'),
      acceptDeadlineAt: json.time('accept_deadline_at'),
      expectedCompletionAt: json.time('expected_completion_at'),
      completedAt: json.time('completed_at'),
      allowedActions: json.strings('allowed_actions').toSet(),
      timeline: [
        for (final item in json.objects('timeline'))
          TaskEvent(
            status: TaskStatus.fromCode(item.strOrNull('status')),
            at: item.time('occurred_at') ?? DateTime.now(),
          ),
      ],
      pendingMedia: [
        for (final item in json.objects('pending_media'))
          TaskMedia.fromJson(item),
      ],
      latestProof: json.object('latest_proof') == null
          ? null
          : TaskProof.fromJson(json.object('latest_proof')!),
      previousProof: json.object('previous_proof') == null
          ? null
          : TaskProof.fromJson(json.object('previous_proof')!),
      proofRejectionReason: json.strOrNull('proof_rejection_reason'),
      canResubmit: json.flag('can_resubmit'),
      feedingLocation: json.object('feeding_location'),
      purchaseRequirements: json.objects('purchase_requirements'),
    );
  }

  FeederTask copyWith({
    TaskStatus? status,
    Set<String>? allowedActions,
    List<TaskMedia>? pendingMedia,
    List<TaskEvent>? timeline,
    TaskProof? latestProof,
    String? proofRejectionReason,
    bool? canResubmit,
    TaskProof? previousProof,
  }) => FeederTask(
    id: id,
    requestId: requestId,
    requestReference: requestReference,
    status: status ?? this.status,
    programName: programName,
    cityName: cityName,
    packageName: packageName,
    mealCount: mealCount,
    foodQuantityGrams: foodQuantityGrams,
    foodBudget: foodBudget,
    feederFee: feederFee,
    currency: currency,
    zoneName: zoneName,
    instructions: instructions,
    assignedAt: assignedAt,
    acceptDeadlineAt: acceptDeadlineAt,
    expectedCompletionAt: expectedCompletionAt,
    completedAt: completedAt,
    allowedActions: allowedActions ?? this.allowedActions,
    timeline: timeline ?? this.timeline,
    pendingMedia: pendingMedia ?? this.pendingMedia,
    latestProof: latestProof ?? this.latestProof,
    previousProof: previousProof ?? this.previousProof,
    proofRejectionReason: proofRejectionReason ?? this.proofRejectionReason,
    canResubmit: canResubmit ?? this.canResubmit,
    feedingLocation: feedingLocation,
    purchaseRequirements: purchaseRequirements,
  );
}

class FeederZone {
  const FeederZone({required this.id, required this.name});

  final String id;
  final String name;

  factory FeederZone.fromJson(Map<String, dynamic> json) => FeederZone(
    id: json.str('id'),
    name: AppLocale.pick(
      json.strOrNull('name_en'),
      json.strOrNull('name_ar'),
      json.strOrNull('name_ur'),
    ),
  );
}

/// `GET /feeders/me`. Works in every verification state.
class FeederProfile {
  const FeederProfile({
    required this.id,
    required this.fullName,
    required this.verificationStatus,
    this.phoneNumber = '',
    this.email = '',
    this.rejectionReason,
    this.programs = const [],
    this.cities = const [],
    this.zones = const [],
    this.isAvailable = false,
    this.dailyCapacity = 3,
    this.tasksCompleted = 0,
    this.bankName,
    this.ibanLastFour,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final VerificationStatus verificationStatus;
  final String? rejectionReason;
  final List<String> programs;

  /// Distinct cities of [programs], e.g. "Makkah".
  final List<String> cities;
  final List<FeederZone> zones;
  final bool isAvailable;
  final int dailyCapacity;
  final int tasksCompleted;
  final String? bankName;

  /// The full IBAN is never returned.
  final String? ibanLastFour;

  factory FeederProfile.fromJson(Map<String, dynamic> json) => FeederProfile(
    id: json.str('id'),
    fullName: json.str('full_name'),
    phoneNumber: json.str('phone_number'),
    email: json.str('email'),
    verificationStatus: VerificationStatus.fromCode(
      json.strOrNull('verification_status'),
    ),
    rejectionReason: json.strOrNull('rejection_reason'),
    programs: [
      for (final item in json.objects('programs'))
        AppLocale.pick(
          item.strOrNull('title_en') ?? item.strOrNull('city_name_en'),
          item.strOrNull('title_ar') ?? item.strOrNull('city_name_ar'),
          item.strOrNull('city_name_ur'),
        ),
    ],
    cities: {
      for (final item in json.objects('programs'))
        AppLocale.pick(
          item.strOrNull('city_name_en'),
          item.strOrNull('city_name_ar'),
          item.strOrNull('city_name_ur'),
        ),
    }.where((city) => city.isNotEmpty).toList(),
    // `zones` is a list of ids; the names come in `zone_details`.
    zones: [
      for (final item
          in json.objects('zone_details').isNotEmpty
              ? json.objects('zone_details')
              : json.objects('zones'))
        FeederZone.fromJson(item),
    ],
    isAvailable: json.flag('is_available'),
    dailyCapacity: json.integer('daily_capacity', 3),
    tasksCompleted: json.integer('tasks_completed'),
    bankName: json.strOrNull('bank_name'),
    ibanLastFour: json.strOrNull('iban_last_four'),
  );

  FeederProfile copyWith({bool? isAvailable, int? dailyCapacity}) =>
      FeederProfile(
        id: id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        verificationStatus: verificationStatus,
        rejectionReason: rejectionReason,
        programs: programs,
        cities: cities,
        zones: zones,
        isAvailable: isAvailable ?? this.isAvailable,
        dailyCapacity: dailyCapacity ?? this.dailyCapacity,
        tasksCompleted: tasksCompleted,
        bankName: bankName,
        ibanLastFour: ibanLastFour,
      );
}

/// `GET /feeder/dashboard/summary`.
class FeederDashboard {
  const FeederDashboard({
    this.newTasks = 0,
    this.activeTasks = 0,
    this.completedTasks = 0,
    this.isAvailable = false,
    this.dailyCapacity = 3,
    this.payoutsByCurrency = const {},
  });

  final int newTasks;
  final int activeTasks;
  final int completedTasks;
  final bool isAvailable;
  final int dailyCapacity;

  /// Eligible payout per currency, e.g. `{"SAR": "30.00"}`.
  final Map<String, String> payoutsByCurrency;

  /// One label per currency, since amounts in different currencies can't be
  /// added together.
  String get eligiblePayoutLabel => payoutsByCurrency.isEmpty
      ? '0'
      : payoutsByCurrency.entries
            .map((entry) => formatMoney(entry.value, entry.key))
            .join(' · ');

  factory FeederDashboard.fromJson(Map<String, dynamic> json) {
    final byCurrency = json.object('eligible_payouts_by_currency') ?? const {};
    final single = json.strOrNull('eligible_payout_amount');
    final currency = json.strOrNull('currency');
    return FeederDashboard(
      newTasks: json.integer('new_tasks'),
      activeTasks: json.integer('active_tasks'),
      completedTasks: json.integer('completed_tasks'),
      isAvailable: json.flag('is_available'),
      dailyCapacity: json.integer('daily_capacity', 3),
      payoutsByCurrency: byCurrency.isNotEmpty
          ? {
              for (final entry in byCurrency.entries)
                entry.key: '${entry.value}',
            }
          : {if (single != null && currency != null) currency: single},
    );
  }
}

enum PayoutStatus {
  eligible,
  approved,
  paid,
  cancelled,
  unknown;

  String get label => switch (this) {
    eligible => 'Eligible'.tr,
    approved => 'Approved'.tr,
    paid => 'Paid'.tr,
    cancelled => 'Cancelled'.tr,
    unknown => 'Updating'.tr,
  };

  static PayoutStatus fromCode(String? code) =>
      values.firstWhere((status) => status.name == code, orElse: () => unknown);
}

/// `GET /feeder/payouts` item. Read-only; finance handles payouts in the CMS.
class FeederPayout {
  const FeederPayout({
    required this.id,
    required this.requestReference,
    required this.amount,
    required this.currency,
    required this.status,
    this.eligibleAt,
    this.paidAt,
  });

  final String id;
  final String requestReference;
  final String amount;
  final String currency;
  final PayoutStatus status;
  final DateTime? eligibleAt;
  final DateTime? paidAt;

  String get amountLabel => formatMoney(amount, currency);

  factory FeederPayout.fromJson(Map<String, dynamic> json) => FeederPayout(
    id: json.str('id'),
    requestReference: json.str('request_reference'),
    amount: json.str('amount', '0.00'),
    currency: json.str('currency', 'SAR'),
    status: PayoutStatus.fromCode(json.strOrNull('status')),
    eligibleAt: json.time('eligible_at'),
    paidAt: json.time('paid_at'),
  );
}

/// The operator application (`POST /feeders/apply`, multipart).
class FeederApplication {
  const FeederApplication({
    required this.programId,
    required this.fullName,
    required this.phoneNumber,
    required this.zoneIds,
    required this.bankAccountHolderName,
    required this.bankName,
    required this.iban,
    required this.dailyCapacity,
    required this.idFrontPath,
    required this.idBackPath,
    required this.selfiePath,
    this.email,
  });

  final String programId;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final List<String> zoneIds;
  final String bankAccountHolderName;
  final String bankName;
  final String iban;
  final int dailyCapacity;
  final String idFrontPath;
  final String idBackPath;
  final String selfiePath;
}

/// The proof sent with `POST /feeder/tasks/{id}/proof`.
class ProofSubmission {
  const ProofSubmission({
    required this.latitude,
    required this.longitude,
    required this.gpsAccuracyM,
    required this.mealCount,
    required this.animalsFedEstimate,
    required this.fedAt,
    this.feederNote = '',
    this.receiptAmount,
    this.mediaIds,
    this.deviceMetadata = const {},
  });

  final double latitude;
  final double longitude;
  final double gpsAccuracyM;
  final int mealCount;
  final int animalsFedEstimate;
  final DateTime fedAt;
  final String feederNote;

  /// Money string, e.g. `"92.50"`.
  final String? receiptAmount;

  /// Null attaches every unsubmitted upload of the task.
  final List<String>? mediaIds;
  final Map<String, dynamic> deviceMetadata;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'gps_accuracy_m': gpsAccuracyM,
    'meal_count': mealCount,
    'animals_fed_estimate': animalsFedEstimate,
    'fed_at': fedAt.toUtc().toIso8601String(),
    if (feederNote.isNotEmpty) 'feeder_note': feederNote,
    if (receiptAmount != null && receiptAmount!.isNotEmpty)
      'receipt_amount': receiptAmount,
    'media_ids': ?mediaIds,
    if (deviceMetadata.isNotEmpty) 'device_metadata': deviceMetadata,
  };
}
