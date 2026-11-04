import '../../../apis/core/api_response.dart';
import '../../core/services/cache_service.dart';
import '../datasources/charity_data_source.dart';
import '../models/charity_campaign.dart';
import '../models/charity_package.dart';
import '../models/charity_request_detail.dart';
import '../models/donation_receipt.dart';

class CharityRepository {
  CharityRepository(this._dataSource, this._cacheService);

  /// Last fetched page of the donor's requests, so the tabs render at once.
  static const _historyKey = 'charity_requests_cache_v2';

  /// Enough for the home and impact summaries; the requests tab pages on.
  static const historyPageSize = 50;

  final CharityDataSource _dataSource;
  final CacheService _cacheService;

  /// Whether the server has more requests than [getDonationHistory] holds.
  bool hasMoreHistory = false;
  int _historyPage = 1;

  Future<List<CharityCampaign>> getCampaigns() {
    return _dataSource.fetchCampaigns();
  }

  Future<List<CharityPackage>> getPackages(String campaignId) {
    return _dataSource.fetchPackages(campaignId);
  }

  /// Recent approved feedings across [campaigns], newest first.
  Future<List<FeedingHighlight>> getHighlights(
    List<CharityCampaign> campaigns, {
    int limit = 10,
  }) async {
    final lists = await Future.wait([
      for (final campaign in campaigns.take(4))
        _dataSource.fetchHighlights(campaign.id, limit: limit),
    ]);
    final all = [for (final list in lists) ...list]
      ..sort(
        (a, b) => (b.fedAt ?? DateTime(0)).compareTo(a.fedAt ?? DateTime(0)),
      );
    return all.take(limit).toList(growable: false);
  }

  /// Cached requests, newest first. Call [refreshDonationHistory] for the
  /// server's latest.
  List<DonationReceipt> getDonationHistory() {
    return _cacheService
        .readJsonList(_historyKey)
        .map(DonationReceipt.fromJson)
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Fetches the first page of requests from the server.
  Future<List<DonationReceipt>> refreshDonationHistory() async {
    final page = await _dataSource.fetchMyRequests(pageSize: historyPageSize);
    _historyPage = 1;
    hasMoreHistory = page.meta.hasNext;
    await _saveHistory(_keepProgramme(page.items));
    return getDonationHistory();
  }

  /// Appends the next page of requests.
  Future<List<DonationReceipt>> loadMoreDonationHistory() async {
    if (!hasMoreHistory) return getDonationHistory();
    final page = await _dataSource.fetchMyRequests(
      page: _historyPage + 1,
      pageSize: historyPageSize,
    );
    _historyPage++;
    hasMoreHistory = page.meta.hasNext;
    final known = {for (final item in page.items) item.requestId};
    await _saveHistory([
      ...getDonationHistory().where((item) => !known.contains(item.requestId)),
      ..._keepProgramme(page.items),
    ]);
    return getDonationHistory();
  }

  Future<PagedList<DonationReceipt>> getRequestsPage({
    int page = 1,
    String? status,
  }) => _dataSource.fetchMyRequests(page: page, status: status);

  /// Loads [request]'s progress and stores its latest status for the lists.
  Future<CharityRequestDetail> getRequestDetail(DonationReceipt request) =>
      getRequestDetailById(request.requestId);

  Future<CharityRequestDetail> getRequestDetailById(String requestId) async {
    final detail = await _dataSource.fetchRequestDetail(requestId);
    await _saveStatus(detail.request);
    return detail;
  }

  Future<CharityRequestDetail> cancelRequest(
    DonationReceipt request, {
    String? reason,
  }) async {
    final detail = await _dataSource.cancelRequest(
      request.requestId,
      reason: reason,
    );
    await _saveStatus(detail.request);
    return detail;
  }

  /// Dev/staging only: the mock checkout that funds a draft request.
  Future<String?> getCheckoutUrl(DonationReceipt request) =>
      _dataSource.createPaymentIntent(request.requestId);

  Future<DonationReceipt> createRequest({
    required CharityCampaign campaign,
    required CharityPackage package,
    required DonorDetails donor,
  }) async {
    final receipt = await _dataSource.createRequest(
      campaign: campaign,
      package: package,
      donor: donor,
    );
    await _saveHistory([receipt, ...getDonationHistory()]);
    return receipt;
  }

  /// Drops the cached requests, e.g. on sign-out.
  Future<void> clearCache() => _cacheService.remove(_historyKey);

  /// `GET /requests/my` sends only the city; keep the programme title and
  /// animal already known from creating or opening each request.
  List<DonationReceipt> _keepProgramme(List<DonationReceipt> items) {
    final known = {
      for (final item in getDonationHistory()) item.requestId: item,
    };
    return [
      for (final item in items)
        switch (known[item.requestId]) {
          final cached?
              when item.campaignId.isEmpty && cached.campaignId.isNotEmpty =>
            item.withProgrammeOf(cached),
          _ => item,
        },
    ];
  }

  Future<void> _saveStatus(DonationReceipt updated) => _saveHistory([
    for (final item in getDonationHistory())
      item.requestId == updated.requestId ? updated : item,
  ]);

  Future<void> _saveHistory(List<DonationReceipt> requests) =>
      _cacheService.writeJsonList(
        _historyKey,
        requests.map((item) => item.toJson()).toList(growable: false),
      );
}
