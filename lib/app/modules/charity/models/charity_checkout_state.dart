import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_package.dart';
import '../../../data/models/donation_receipt.dart';

class CharityCheckoutState {
  const CharityCheckoutState({
    required this.campaign,
    required this.package,
    this.isSubmitting = false,
    this.receipt,
    this.error,
    this.fieldErrors = const {},
  });

  final CharityCampaign campaign;
  final CharityPackage package;
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
      isSubmitting: isSubmitting ?? this.isSubmitting,
      receipt: receipt ?? this.receipt,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: clearError ? const {} : (fieldErrors ?? this.fieldErrors),
    );
  }
}
