import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_package.dart';
import '../../../data/models/donation_receipt.dart';

class CharityCheckoutState {
  const CharityCheckoutState({
    required this.campaign,
    required this.package,
    this.isSubmitting = false,
    this.lines = const [],
    this.receipt,
    this.error,
    this.fieldErrors = const {},
  });

  final CharityCampaign campaign;
  final CharityPackage package;
  final List<DonationLine> lines;
  List<DonationLine> get items =>
      lines.isEmpty ? [DonationLine(item: package, quantity: 1)] : lines;
  String get totalLabel => hasMixedCurrencies ? '—' : basketTotalLabel(items);
  bool get canSubmitLegacyRequest =>
      items.length == 1 && items.single.quantity == 1;
  bool get hasMixedCurrencies =>
      items.map((l) => l.item.currency).toSet().length > 1;
  final bool isSubmitting;
  final DonationReceipt? receipt;
  final String? error;

  /// Per-field messages from a `validation_error`, keyed by API field.
  final Map<String, String> fieldErrors;

  CharityCheckoutState copyWith({
    bool? isSubmitting,
    DonationReceipt? receipt,
    String? error,
    Map<String, String>? fieldErrors,
    bool clearError = false,
  }) {
    return CharityCheckoutState(
      campaign: campaign,
      package: package,
      lines: lines,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      receipt: receipt ?? this.receipt,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }
}
