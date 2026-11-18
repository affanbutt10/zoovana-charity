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
  final int? mealCount;
  final int? foodQuantityGrams;
  final int? animalsFedEstimate;
  final String approximateZone;
  final DateTime approvedAt;
  final String feederNote;

  factory DonationProof.fromJson(Map<String, dynamic> json) => DonationProof(
    media: [
      for (final item in json.objects('media')) ProofMedia.fromJson(item),
    ],
    mealCount: json['meal_count'] == null ? null : json.integer('meal_count'),
    foodQuantityGrams: json['food_quantity_grams'] == null
        ? null
        : json.integer('food_quantity_grams'),
    animalsFedEstimate: json['animals_fed_estimate'] == null
        ? null
        : json.integer('animals_fed_estimate'),
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
    this.feedingAt,
    this.feedingNotes = '',
    this.items = const [],
    this.zoneName,
    this.progress,
  });

  /// The request with its latest status.
  final DonationReceipt request;
  final List<RequestEvent> timeline;
  final DateTime? expectedCompletionAt;
  final DonationProof? proof;
  final DateTime? feedingAt;
  final String feedingNotes;
  final List<RequestFeedingItem> items;
  final String? zoneName;
  final FeedingProgress? progress;

  DonationStatus get status => request.status;

  /// `GET /requests/{id}`.
  factory CharityRequestDetail.fromApi(Map<String, dynamic> json) {
    final proof = json.object('proof');
    final request = DonationReceipt.fromApi(json);
    final rawItems = json.objects('items').isNotEmpty
        ? json.objects('items')
        : json.objects('feeding_items');
    final package = json.object('package');
    return CharityRequestDetail(
      request: request,
      zoneName: json.object('zone')?.strOrNull('name'),
      progress: json.object('progress') == null
          ? null
          : FeedingProgress.fromJson(json.object('progress')!),
      feedingAt: json.time('fed_at') ?? proof?.time('fed_at'),
      feedingNotes: json.strOrNull('feeding_notes') ?? json.str('notes'),
      items: rawItems.isNotEmpty
          ? [
              for (final item in rawItems)
                RequestFeedingItem.fromJson(item, currency: request.currency),
            ]
          : [
              RequestFeedingItem(
                name: request.packageName,
                description:
                    package?.strOrNull('description') ??
                    package?.str('description_en') ??
                    '',
                imageUrl: package?.strOrNull('image_url'),
                unitAmount: request.amount,
                currency: request.currency,
                quantity: 1,
              ),
            ],
      timeline: [
        for (final item in json.objects('timeline'))
          RequestEvent.fromJson(item),
      ],
      expectedCompletionAt: json.time('expected_completion_at'),
      proof: proof == null ? null : DonationProof.fromJson(proof),
    );
  }
}

/// Item information required by the updated donor details view.
class RequestFeedingItem {
  const RequestFeedingItem({
    required this.name,
    this.description = '',
    this.imageUrl,
    this.unitAmount,
    this.currency = '',
    this.quantity,
  });
  final String name, description, currency;
  final String? imageUrl, unitAmount;
  final int? quantity;
  factory RequestFeedingItem.fromJson(
    Map<String, dynamic> json, {
    required String currency,
  }) {
    final package = json.object('package');
    return RequestFeedingItem(
      name: json.strOrNull('name') ?? package?.str('name') ?? '',
      description:
          json.strOrNull('description') ?? package?.str('description') ?? '',
      imageUrl: json.strOrNull('image_url') ?? package?.strOrNull('image_url'),
      unitAmount:
          json.strOrNull('unit_amount') ??
          json.strOrNull('unit_price') ??
          json.strOrNull('amount') ??
          package?.strOrNull('price'),
      currency: json.strOrNull('currency') ?? currency,
      quantity: json['quantity'] == null ? null : json.integer('quantity'),
    );
  }
}

class FeedingProgress {
  FeedingProgress.fromJson(Map<String, dynamic> json)
    : stages = [
        for (final s in json.objects('stages'))
          FeedingProgressStage.fromJson(s),
      ],
      currentStage = json.strOrNull('current_stage'),
      haltedStatus = json.strOrNull('halted_status'),
      estimatedCompletionAt = json.time('estimated_completion_at');
  final List<FeedingProgressStage> stages;
  final String? currentStage, haltedStatus;
  final DateTime? estimatedCompletionAt;
}

class FeedingProgressStage {
  FeedingProgressStage.fromJson(Map<String, dynamic> json)
    : key = json.str('key'),
      label = json.str('label'),
      state = json.str('state'),
      occurredAt = json.str('state') == 'done'
          ? json.time('occurred_at')
          : null;
  final String key, label, state;
  final DateTime? occurredAt;
}
