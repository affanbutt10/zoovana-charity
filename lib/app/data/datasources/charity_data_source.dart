import 'package:dio/dio.dart';

import '../../../apis/core/api_client.dart';
import '../../../apis/core/api_endpoints.dart';
import '../../../apis/core/api_response.dart';
import '../../core/errors/app_error.dart';
import '../../core/services/app_locale.dart';
import '../../core/services/cache_service.dart';
import '../models/charity_campaign.dart';
import '../models/charity_package.dart';
import '../models/charity_request_detail.dart';
import '../models/donation_receipt.dart';

abstract interface class CharityDataSource {
  Future<List<CharityCampaign>> fetchCampaigns();

  Future<List<CharityPackage>> fetchPackages(String campaignId);

  /// Anonymised approved feedings of a programme.
  Future<List<FeedingHighlight>> fetchHighlights(
    String campaignId, {
    int limit = 10,
  });

  /// Creates a request (`POST /requests`). It starts as `draft` until paid.
  Future<DonationReceipt> createRequest({
    required CharityCampaign campaign,
    required CharityPackage package,
    required DonorDetails donor,
  });

  /// The signed-in donor's requests, newest first (`GET /requests/my`).
  Future<PagedList<DonationReceipt>> fetchMyRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
  });

  /// Latest status, donor-safe timeline and approved proof
  /// (`GET /requests/{request_id}`).
  Future<CharityRequestDetail> fetchRequestDetail(String requestId);

  /// Cancels an unpaid request.
  Future<CharityRequestDetail> cancelRequest(
    String requestId, {
    String? reason,
  });

  /// The mock checkout URL used to fund drafts in dev and staging, or null
  /// when there is none.
  Future<String?> createPaymentIntent(String requestId);
}

class RemoteCharityDataSource implements CharityDataSource {
  RemoteCharityDataSource(this._client);

  final ApiClient _client;
  Dio get _dio => _client.feeding;

  @override
  Future<List<CharityCampaign>> fetchCampaigns() async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.programs,
      queryParameters: const {'page_size': 100},
    );
    return [
      for (final item in response.dataList)
        if (item['is_active'] != false) CharityCampaign.fromApi(item),
    ];
  }

  @override
  Future<List<CharityPackage>> fetchPackages(String campaignId) async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.packages(campaignId),
    );
    return [
      for (final item in response.dataList)
        if (item['is_active'] != false) CharityPackage.fromApi(item),
    ];
  }

  @override
  Future<List<FeedingHighlight>> fetchHighlights(
    String campaignId, {
    int limit = 10,
  }) async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.highlights(campaignId),
      queryParameters: {'limit': limit.clamp(1, 30)},
    );
    return [
      for (final item in response.dataList) FeedingHighlight.fromApi(item),
    ];
  }

  @override
  Future<DonationReceipt> createRequest({
    required CharityCampaign campaign,
    required CharityPackage package,
    required DonorDetails donor,
  }) async {
    final response = await _dio.post<dynamic>(
      FeedingEndpoints.requests,
      data: {
        'package_id': package.id,
        'full_name': donor.fullName,
        'email': donor.email,
        'phone_number': donor.phoneNumber,
        'country_code': donor.countryCode,
        if (donor.dedication.isNotEmpty) 'dedication': donor.dedication,
        'is_anonymous': donor.isAnonymous,
        'notify_push': donor.notifyPush,
        'notify_email': donor.notifyEmail,
        'locale': AppLocale.code,
      },
    );
    return DonationReceipt.fromApi(response.dataMap);
  }

  @override
  Future<PagedList<DonationReceipt>> fetchMyRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.myRequests,
      queryParameters: {
        'page': page,
        'page_size': pageSize.clamp(1, 100),
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return response.paged(DonationReceipt.fromApi);
  }

  @override
  Future<CharityRequestDetail> fetchRequestDetail(String requestId) async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.request(requestId),
    );
    return CharityRequestDetail.fromApi(response.dataMap);
  }

  @override
  Future<CharityRequestDetail> cancelRequest(
    String requestId, {
    String? reason,
  }) async {
    final response = await _dio.post<dynamic>(
      FeedingEndpoints.cancelRequest(requestId),
      data: {'reason': ?reason},
    );
    return CharityRequestDetail.fromApi(response.dataMap);
  }

  @override
  Future<String?> createPaymentIntent(String requestId) async {
    final response = await _dio.post<dynamic>(
      FeedingEndpoints.paymentIntent(requestId),
    );
    final url = response.dataMap
        .object('client_payload')
        ?.strOrNull('checkout_url');
    return url == null ? null : _publicCheckoutUrl(url);
  }

  /// The mock provider can build its link from the server's internal
  /// address (`http://localhost:8013/...`), which a phone can't open. Keep the
  /// path and swap in the feeding host the app already talks to.
  String _publicCheckoutUrl(String url) {
    final uri = Uri.tryParse(url);
    const internal = {'localhost', '127.0.0.1', '0.0.0.0'};
    if (uri == null || !internal.contains(uri.host)) return url;
    final api = Uri.parse(_dio.options.baseUrl);
    return uri
        .replace(scheme: api.scheme, host: api.host, port: api.port)
        .toString();
  }
}

/// Local data keeps the app runnable without a backend. [AppBootstrap] picks
/// the remote implementation once the service URLs are configured.
class SeedCharityDataSource implements CharityDataSource {
  SeedCharityDataSource(this._cache);

  /// The seed backend's own request store.
  static const storeKey = 'charity_donation_history_v1';
  final CacheService _cache;

  List<DonationReceipt> get _stored =>
      _cache.readJsonList(storeKey).map(DonationReceipt.fromJson).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _save(List<DonationReceipt> requests) => _cache.writeJsonList(
    storeKey,
    [for (final item in requests) item.toJson()],
  );

  @override
  Future<List<CharityCampaign>> fetchCampaigns() async {
    return const [
      CharityCampaign(
        id: 'makkah-cats',
        code: 'MAKKAH-CATS',
        title: 'Feed Cats in Makkah',
        city: 'Makkah',
        cityCode: 'makkah',
        animal: 'Cats',
        animalKind: AnimalKind.cat,
        description: 'Offer food and gentle care to community cats in Makkah.',
        supporters: 1240,
        fulfilmentSlaHours: 48,
      ),
      CharityCampaign(
        id: 'madinah-birds',
        code: 'MADINAH-BIRDS',
        title: 'Feed Birds in Al-Madinah',
        city: 'Al-Madinah',
        cityCode: 'madinah',
        animal: 'Birds',
        animalKind: AnimalKind.bird,
        description:
            'Share food and water with birds in the city of the Prophet ﷺ.',
        supporters: 816,
        fulfilmentSlaHours: 48,
      ),
      CharityCampaign(
        id: 'madinah-cats',
        code: 'MADINAH-CATS',
        title: 'Feed Cats in Al-Madinah',
        city: 'Al-Madinah',
        cityCode: 'madinah',
        animal: 'Cats',
        animalKind: AnimalKind.cat,
        description: 'Help provide nourishing meals for community cats.',
        supporters: 492,
        fulfilmentSlaHours: 48,
      ),
    ];
  }

  @override
  Future<List<CharityPackage>> fetchPackages(String campaignId) async {
    return [
      CharityPackage(
        id: '$campaignId-mango',
        name: 'Mango Sunrise',
        price: '123.40',
        impact: 'Approximately 25 meals',
        food: 'Crunchy dental treats with natural mango and oats',
        recommended: true,
        mealCount: 25,
        foodQuantityGrams: 1500,
      ),
      CharityPackage(
        id: '$campaignId-kisses',
        name: 'Fresh kisses',
        price: '123.40',
        impact: 'Approximately 25 meals',
        food: 'Double-brush treats that keep teeth and breath fresh',
        mealCount: 25,
        foodQuantityGrams: 1500,
      ),
      CharityPackage(
        id: '$campaignId-chews',
        name: 'Dental Chews',
        price: '98.50',
        impact: 'Approximately 20 meals',
        food: 'Gentle chews suitable for street animals of all ages',
        mealCount: 20,
        foodQuantityGrams: 1200,
      ),
      CharityPackage(
        id: '$campaignId-salmon',
        name: 'Salmon Bites',
        price: '110.00',
        impact: 'Approximately 22 meals',
        food: 'High-protein salmon bites for a nourishing meal',
        mealCount: 22,
        foodQuantityGrams: 1320,
      ),
    ];
  }

  @override
  Future<List<FeedingHighlight>> fetchHighlights(
    String campaignId, {
    int limit = 10,
  }) async {
    final makkah = campaignId.startsWith('makkah');
    return [
      FeedingHighlight(
        id: '$campaignId-h1',
        programId: campaignId,
        zone: makkah ? 'Al-Aziziyah' : 'Quba',
        mealCount: 50,
        animalsFedEstimate: 35,
        fedAt: DateTime.now().subtract(const Duration(hours: 5)),
        note: 'Every portion was eaten and fresh water was left out.',
        imageUrl: 'assets/images/charity_street.jpg',
      ),
    ].take(limit).toList(growable: false);
  }

  @override
  Future<DonationReceipt> createRequest({
    required CharityCampaign campaign,
    required CharityPackage package,
    required DonorDetails donor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final now = DateTime.now();
    final suffix = now.millisecondsSinceEpoch.toString().substring(7);
    // The seed backend funds requests at once, as the dev mock checkout does.
    final receipt = DonationReceipt(
      reference: 'ZF-$suffix',
      campaignId: campaign.id,
      campaignTitle: campaign.title,
      city: campaign.city,
      packageName: package.name,
      amount: package.price,
      currency: package.currency,
      impact: package.impact,
      meals: package.mealCount,
      dedication: donor.dedication,
      createdAt: now,
      animalType: campaign.animalKind.name,
      expectedCompletionAt: now.add(
        Duration(hours: package.fulfilmentSlaHours ?? 24),
      ),
    );
    await _save([receipt, ..._stored]);
    return receipt;
  }

  @override
  Future<PagedList<DonationReceipt>> fetchMyRequests({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final all = [for (final request in _stored) _withDemoStatus(request)]
        .where((request) => status == null || request.status.code == status);
    final items = all.skip((page - 1) * pageSize).take(pageSize).toList();
    return PagedList(
      items,
      PageMeta(
        page: page,
        pageSize: pageSize,
        total: all.length,
        hasNext: page * pageSize < all.length,
      ),
    );
  }

  @override
  Future<CharityRequestDetail> fetchRequestDetail(String requestId) async {
    final request = _find(requestId);
    if (request.status == DonationStatus.cancelled) {
      return CharityRequestDetail(
        request: request,
        timeline: [
          RequestEvent(status: DonationStatus.draft, at: request.createdAt),
          RequestEvent(status: DonationStatus.cancelled, at: request.createdAt),
        ],
      );
    }
    return _demoDetail(request);
  }

  @override
  Future<CharityRequestDetail> cancelRequest(
    String requestId, {
    String? reason,
  }) async {
    final request = _withDemoStatus(_find(requestId));
    if (!request.status.isUnpaid) {
      throw const AppError(
        type: AppErrorType.server,
        statusCode: 409,
        code: ApiErrorCode.invalidStateTransition,
        message: 'Only unpaid requests can be cancelled.',
      );
    }
    await _save([
      for (final item in _stored)
        item.requestId == requestId
            ? item.withStatus(DonationStatus.cancelled)
            : item,
    ]);
    return fetchRequestDetail(requestId);
  }

  @override
  Future<String?> createPaymentIntent(String requestId) async => null;

  DonationReceipt _find(String requestId) {
    final match = _stored.where(
      (item) => item.requestId == requestId || item.reference == requestId,
    );
    if (match.isEmpty) {
      throw const AppError(
        type: AppErrorType.server,
        statusCode: 404,
        message: 'This request could not be found.',
      );
    }
    return match.first;
  }

  /// Demo-only progression: each request advances one stage every
  /// [_demoStageDuration] after it is placed, so the full timeline and proof
  /// can be seen without a backend. The API owns real transitions.
  static const _demoStageDuration = Duration(seconds: 30);

  static const _demoStages = [
    (
      DonationStatus.assigned,
      'A verified local operator accepted your request.',
      <String>[],
    ),
    (
      DonationStatus.purchasing,
      'The food for your package has been bought.',
      ['assets/images/feeding_cat_food.jpg'],
    ),
    (
      DonationStatus.feeding,
      'The feeding round has started in your chosen area.',
      ['assets/images/charity_street.jpg', 'assets/images/home_donate.jpg'],
    ),
    (
      DonationStatus.proofSubmitted,
      'Photos were submitted and are being reviewed.',
      <String>[],
    ),
    (
      DonationStatus.completed,
      'The feeding was verified. Thank you for your support!',
      <String>[],
    ),
  ];

  DonationReceipt _withDemoStatus(DonationReceipt request) {
    if (request.status.isFinal || request.status.isUnpaid) return request;
    return _demoDetail(request).request;
  }

  CharityRequestDetail _demoDetail(DonationReceipt request) {
    final elapsed = DateTime.now().difference(request.createdAt);
    final reached = (elapsed.inSeconds ~/ _demoStageDuration.inSeconds).clamp(
      0,
      _demoStages.length,
    );
    final timeline = [
      RequestEvent(
        status: DonationStatus.awaitingAssignment,
        at: request.createdAt,
        note: 'We received your request and are finding a local operator.',
      ),
      for (var i = 0; i < reached; i++)
        RequestEvent(
          status: _demoStages[i].$1,
          at: request.createdAt.add(_demoStageDuration * (i + 1)),
          note: _demoStages[i].$2,
          media: [
            for (final asset in _demoStages[i].$3) ProofMedia(url: asset),
          ],
        ),
    ];
    final status = timeline.last.status;
    final meals = request.mealCount;
    return CharityRequestDetail(
      request: request.withStatus(status),
      timeline: timeline,
      expectedCompletionAt: status.isFinal
          ? null
          : request.expectedCompletionAt ??
                request.createdAt.add(const Duration(hours: 24)),
      proof: status != DonationStatus.completed
          ? null
          : DonationProof(
              media: const [
                ProofMedia(
                  url: 'assets/images/charity_street.jpg',
                  caption: 'Cats gathering for the meal',
                ),
                ProofMedia(
                  url: 'assets/images/home_donate.jpg',
                  caption: 'Serving the food',
                ),
                ProofMedia(
                  url: 'assets/images/feeding_cat_food.jpg',
                  caption: 'Food used in this round',
                ),
              ],
              mealCount: meals,
              foodQuantityGrams: meals * 60,
              animalsFedEstimate: (meals * .7).round(),
              approximateZone: request.city == 'Makkah'
                  ? 'Al-Aziziyah, Makkah'
                  : 'Quba, Al-Madinah',
              approvedAt: timeline.last.at,
              feederNote:
                  'The animals gathered quickly and every portion was eaten. '
                  'Fresh water was left in the area as well.',
            ),
    );
  }
}
