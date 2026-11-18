import 'package:get/get.dart';

import '../../../apis/core/api_response.dart';
import '../../core/services/app_locale.dart';
import 'charity_campaign.dart';
import 'charity_package.dart';

/// Operational state of a charity request, owned by the backend. [code] is the
/// API value; [label] is a fallback for when the API sends no `status_label`.
/// The status only picks icons and colours; screens show the API's label.
enum DonationStatus {
  draft('draft', 'Draft'),
  paymentPending('payment_pending', 'Payment pending'),
  paid('paid', 'Finding an operator'),
  awaitingAssignment('awaiting_assignment', 'Finding an operator'),
  assigned('assigned', 'Operator assigned'),
  accepted('accepted', 'Preparing food'),
  purchasing('purchasing', 'Preparing food'),
  feeding('feeding', 'Feeding in progress'),
  proofSubmitted('proof_submitted', 'Proof under review'),
  proofRejected('proof_rejected', 'Verifying proof'),
  reassignmentRequired('reassignment_required', 'Arranging an operator'),
  completed('completed', 'Feeding completed'),
  cancelled('cancelled', 'Cancelled'),
  refunded('refunded', 'Refunded'),

  /// A status this app version doesn't know; its API label is still shown.
  unknown('unknown', 'In progress');

  const DonationStatus(this.code, this.label);

  final String code;
  final String label;

  bool get isCompleted => this == completed;

  /// No further progress is expected once a request reaches these states.
  bool get isFinal =>
      this == completed || this == cancelled || this == refunded;

  /// Only unpaid requests can be cancelled from the app.
  bool get isUnpaid => this == draft || this == paymentPending;

  static DonationStatus fromCode(String? code) =>
      values.firstWhere((status) => status.code == code, orElse: () => unknown);
}

/// One charity request as listed in "My requests".
class DonationReceipt {
  const DonationReceipt({
    required this.reference,
    required this.campaignId,
    required this.campaignTitle,
    required this.city,
    required this.packageName,
    required this.amount,
    required this.impact,
    required this.createdAt,
    this.paymentStatus = '',
    this.totalQuantity,
    this.amountMinor,
    this.id = '',
    this.currency = 'SAR',
    this.dedication = '',
    this.status = DonationStatus.awaitingAssignment,
    this.statusLabel,
    this.meals,
    this.hasProof = false,
    this.expectedCompletionAt,
    this.animalType = '',
    this.imageUrl,
  });

  /// Request UUID; seed requests use their reference.
  final String id;
  final String reference;
  final String campaignId;
  final String campaignTitle;
  final String city;
  final String packageName;

  /// Two-decimal money string, e.g. `"75.00"`.
  final String amount;
  final String currency;
  final String impact;
  final DateTime createdAt;
  final String dedication;
  final DonationStatus status;

  /// Localized label from the API.
  final String? statusLabel;
  final int? meals;
  final bool hasProof;
  final DateTime? expectedCompletionAt;

  /// The programme's `animal_type`; empty for requests cached before the app
  /// kept it.
  final String animalType;

  /// Programme cover illustration; never represents approved feeding proof.
  final String? imageUrl;

  /// Falls back to the title for older cached and seed requests.
  AnimalKind get animalKind {
    final kind = AnimalKind.fromCode(animalType);
    if (kind != AnimalKind.other || animalType.isNotEmpty) return kind;
    final text = '$campaignId $campaignTitle'.toLowerCase();
    if (text.contains('bird')) return AnimalKind.bird;
    if (text.contains('dog')) return AnimalKind.dog;
    return AnimalKind.cat;
  }

  final String paymentStatus;
  final int? totalQuantity, amountMinor;
  String get requestId => id.isEmpty ? reference : id;

  String get label => statusLabel ?? status.label.tr;

  /// The API's label in the app language. Without an Urdu label the app's
  /// own translation is used rather than the English one.
  static String? _statusLabel(
    Map<String, dynamic> json,
    Map<String, dynamic>? labels,
  ) {
    if (AppLocale.code == 'ur' && labels?.strOrNull('ur') == null) return null;
    if (labels == null) return json.strOrNull('status_label');
    return AppLocale.pick(
      labels.strOrNull('en') ?? json.strOrNull('status_label'),
      labels.strOrNull('ar'),
      labels.strOrNull('ur'),
    );
  }

  String get amountLabel => amountMinor == null
      ? formatMoney(amount, currency)
      : '${(amountMinor! / 100).toStringAsFixed(2)} $currency';

  /// Meals funded; read from the impact text for requests stored before the
  /// API sent `meal_count`.
  int get mealCount {
    if (meals != null) return meals!;
    final match = RegExp(r'(\d+)\s*meal').firstMatch(impact);
    return match == null ? 0 : int.parse(match.group(1)!);
  }

  DonationReceipt withStatus(DonationStatus status, {String? label}) =>
      DonationReceipt(
        id: id,
        paymentStatus: paymentStatus,
        totalQuantity: totalQuantity,
        amountMinor: amountMinor,
        reference: reference,
        campaignId: campaignId,
        campaignTitle: campaignTitle,
        city: city,
        packageName: packageName,
        amount: amount,
        currency: currency,
        impact: impact,
        createdAt: createdAt,
        dedication: dedication,
        status: status,
        statusLabel: label,
        meals: meals,
        hasProof: hasProof || status == DonationStatus.completed,
        expectedCompletionAt: expectedCompletionAt,
        animalType: animalType,
        imageUrl: imageUrl,
      );

  /// [this] with [other]'s programme, for list items that arrive with only
  /// the city.
  DonationReceipt withProgrammeOf(DonationReceipt other) => DonationReceipt(
    id: id,
    paymentStatus: paymentStatus,
    totalQuantity: totalQuantity,
    amountMinor: amountMinor,
    reference: reference,
    campaignId: other.campaignId,
    campaignTitle: other.campaignTitle,
    city: city,
    packageName: packageName,
    amount: amount,
    currency: currency,
    impact: impact,
    createdAt: createdAt,
    dedication: dedication,
    status: status,
    statusLabel: statusLabel,
    meals: meals,
    hasProof: hasProof,
    expectedCompletionAt: expectedCompletionAt,
    animalType: other.animalType,
    imageUrl: imageUrl ?? other.imageUrl,
  );

  /// `GET /requests/my` item, or the summary part of a request detail.
  factory DonationReceipt.fromApi(Map<String, dynamic> json) {
    final program = json.object('program');
    final package = json.object('package');
    final labels = json.object('status_labels');
    final meals = json['meal_count'] ?? package?['meal_count'];
    final mealCount = meals is num ? meals.toInt() : int.tryParse('$meals');
    final city =
        json.strOrNull('program_city') ?? program?.strOrNull('city') ?? '';
    final title = program?.strOrNull('title');
    return DonationReceipt(
      imageUrl: json.strOrNull('image_url') ?? program?.strOrNull('image_url'),
      id: json.str('id'),
      paymentStatus: json.str('payment_status'),
      totalQuantity: json['total_quantity'] == null
          ? null
          : json.integer('total_quantity'),
      amountMinor: json['amount_minor'] == null
          ? null
          : json.integer('amount_minor'),
      reference: json.str('reference'),
      campaignId: program?.str('id') ?? '',
      campaignTitle:
          title ??
          (city.isEmpty
              ? 'Feeding request'.tr
              : 'Feeding in @city'.trParams({'city': city})),
      city: city,
      packageName: json.strOrNull('package_name') ?? package?.str('name') ?? '',
      amount: json.str('amount', '0.00'),
      currency: json.str('currency', 'PKR'),
      impact: mealCount == null
          ? ''
          : 'Approximately @count meals'.trParams({'count': '$mealCount'}),
      createdAt: json.time('created_at') ?? DateTime.now(),
      dedication: json.str('dedication'),
      status: DonationStatus.fromCode(json.strOrNull('status')),
      statusLabel: _statusLabel(json, labels),
      meals: mealCount,
      hasProof: json.flag('has_proof') || json['proof'] != null,
      expectedCompletionAt: json.time('expected_completion_at'),
      animalType:
          program?.strOrNull('animal_type') ?? json.str('program_animal_type'),
    );
  }

  factory DonationReceipt.fromJson(Map<String, dynamic> json) {
    return DonationReceipt(
      id: json['id'] as String? ?? '',
      paymentStatus: json.str('paymentStatus'),
      totalQuantity: (json['totalQuantity'] as num?)?.toInt(),
      amountMinor: (json['amountMinor'] as num?)?.toInt(),
      reference: json['reference'] as String,
      campaignId: json['campaignId'] as String,
      campaignTitle: json['campaignTitle'] as String,
      city: json['city'] as String,
      packageName: json['packageName'] as String,
      amount: '${json['amount']}',
      currency: json['currency'] as String? ?? 'SAR',
      impact: json['impact'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dedication: json['dedication'] as String? ?? '',
      status: DonationStatus.fromCode(json['status'] as String?),
      statusLabel: json['statusLabel'] as String?,
      meals: (json['meals'] as num?)?.toInt(),
      hasProof: json['hasProof'] as bool? ?? false,
      expectedCompletionAt: json['expectedCompletionAt'] == null
          ? null
          : DateTime.tryParse(json['expectedCompletionAt'] as String),
      animalType: json['animalType'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'paymentStatus': paymentStatus,
    'totalQuantity': totalQuantity,
    'amountMinor': amountMinor,
    'reference': reference,
    'campaignId': campaignId,
    'campaignTitle': campaignTitle,
    'city': city,
    'packageName': packageName,
    'amount': amount,
    'currency': currency,
    'impact': impact,
    'createdAt': createdAt.toIso8601String(),
    'dedication': dedication,
    'status': status.code,
    'statusLabel': statusLabel,
    'meals': meals,
    'hasProof': hasProof,
    'expectedCompletionAt': expectedCompletionAt?.toIso8601String(),
    'animalType': animalType,
    'imageUrl': imageUrl,
  };
}
