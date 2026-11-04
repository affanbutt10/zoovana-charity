import '../../../apis/core/api_response.dart';
import 'donation_receipt.dart';

/// Photo or video shared with the donor. [url] is an HTTPS URL from the API
/// or a bundled asset path in the seed data.
class ProofMedia {
  const ProofMedia({
    required this.url,
    this.thumbnailUrl,
    this.caption = '',
    this.isVideo = false,
    this.expiresAt,
  });

  final String url;
  final String? thumbnailUrl;
  final String caption;
  final bool isVideo;

  /// Signed URLs stop working after this; re-fetch the screen for new ones.
  final DateTime? expiresAt;

  bool get isNetwork => url.startsWith('http');

  factory ProofMedia.fromJson(Map<String, dynamic> json) => ProofMedia(
    url: json.str('url'),
    thumbnailUrl: json.strOrNull('thumbnail_url'),
    caption: json.str('caption'),
    isVideo: json.str('media_type') == 'video',
    expiresAt: json.time('expires_at'),
  );
}

/// One donor-safe step of the request timeline.
class RequestEvent {
  const RequestEvent({
    required this.status,
    required this.at,
    this.label = '',
    this.note = '',
    this.media = const [],
  });

  final DonationStatus status;
  final DateTime at;

  /// Localized label from the API.
  final String label;
  final String note;

  /// Photos shared at this step. The API currently sends proof photos only
  /// once they are approved, so this stays empty for API data.
  final List<ProofMedia> media;

  factory RequestEvent.fromJson(Map<String, dynamic> json) => RequestEvent(
    status: DonationStatus.fromCode(json.strOrNull('status')),
    at: json.time('occurred_at') ?? json.time('created_at') ?? DateTime.now(),
    label: json.str('label'),
    note: json.str('note'),
    media: [
      for (final item in json.objects('media')) ProofMedia.fromJson(item),
    ],
  );
}

/// Approved feeding proof. The API returns it only after review.
class DonationProof {
  const DonationProof({
    required this.media,
    required this.mealCount,
    required this.foodQuantityGrams,
    required this.animalsFedEstimate,
    required this.approximateZone,
    required this.approvedAt,
    this.feederNote = '',
  });

  final List<ProofMedia> media;
  final int mealCount;
  final int foodQuantityGrams;
  final int animalsFedEstimate;
  final String approximateZone;
  final DateTime approvedAt;
  final String feederNote;

  factory DonationProof.fromJson(Map<String, dynamic> json) => DonationProof(
    media: [
      for (final item in json.objects('media')) ProofMedia.fromJson(item),
    ],
    mealCount: json.integer('meal_count'),
    foodQuantityGrams: json.integer('food_quantity_grams'),
    animalsFedEstimate: json.integer('animals_fed_estimate'),
    approximateZone: json.str('approximate_zone'),
    approvedAt:
        json.time('approved_at') ?? json.time('completed_at') ?? DateTime.now(),
    feederNote: json.str('feeder_note'),
  );
}

/// Full donor view of a charity request: its status, timeline and proof.
class CharityRequestDetail {
  const CharityRequestDetail({
    required this.request,
    required this.timeline,
    this.expectedCompletionAt,
    this.proof,
  });

  /// The request with its latest status.
  final DonationReceipt request;
  final List<RequestEvent> timeline;
  final DateTime? expectedCompletionAt;
  final DonationProof? proof;

  DonationStatus get status => request.status;

  /// `GET /requests/{id}`.
  factory CharityRequestDetail.fromApi(Map<String, dynamic> json) {
    final proof = json.object('proof');
    return CharityRequestDetail(
      request: DonationReceipt.fromApi(json),
      timeline: [
        for (final item in json.objects('timeline'))
          RequestEvent.fromJson(item),
      ],
      expectedCompletionAt: json.time('expected_completion_at'),
      proof: proof == null ? null : DonationProof.fromJson(proof),
    );
  }
}
