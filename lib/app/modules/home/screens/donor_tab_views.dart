import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/services/app_locale.dart';
import '../../../core/assets/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_request_detail.dart';
import '../../../data/models/donation_receipt.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../routes/shell_router.dart';
import '../../../shared/widgets/donor_shimmers.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/notification_bell.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import 'donor_settings_screens.dart';

abstract final class DonorArtwork {
  static const madinah = 'assets/images/donor/city_madinah.png';
  static const makkah = 'assets/images/donor/city_makkah.png';
  static const catMadinah = 'assets/images/donor/cats_madinah.png';
  static const birds = 'assets/images/donor/birds_feeding.png';
  static const catMakkah = 'assets/images/donor/cats_makkah.png';
  static String request(DonationReceipt request) =>
      request.animalKind == AnimalKind.bird
      ? birds
      : request.city.toLowerCase().contains('mad')
      ? catMadinah
      : catMakkah;
}

String donorDate(DateTime date) =>
    '${date.day} ${AppLocale.shortMonth(date.month)} ${date.year}';
const _muted = TextStyle(color: Color(0xFF92959B), fontSize: 13);
const _title = TextStyle(fontSize: 19, fontWeight: FontWeight.w700);

/// The compact plain brand header in Requests, Impact and Profile. Only Home
/// has the contour background and greeting in the new reference.
class DonorHeader extends StatelessWidget {
  const DonorHeader({super.key});
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: ColoredBox(
      color: AppColors.brand,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: BrandWordmark(),
                  ),
                ),
              ),
              Transform.scale(scale: .9, child: const NotificationBell()),
            ],
          ),
        ),
      ),
    ),
  );
}

class DonorPage extends StatelessWidget {
  const DonorPage({super.key, required this.children, required this.onRefresh});
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const DonorHeader(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              MediaQuery.paddingOf(context).bottom + 100,
            ),
            children: children,
          ),
        ),
      ),
    ],
  );
}

class DonorHomeView extends StatelessWidget {
  const DonorHomeView({
    super.key,
    required this.requests,
    required this.programmes,
    required this.loadingRequests,
    required this.loadingProgrammes,
    required this.onRefresh,
    required this.onOpenRequest,
    required this.onViewRequests,
    required this.onDonate,
    this.error,
    this.onRetry,
  });
  final List<DonationReceipt> requests;
  final List<CharityCampaign> programmes;
  final bool loadingRequests, loadingProgrammes;
  final Future<void> Function() onRefresh;
  final ValueChanged<DonationReceipt> onOpenRequest;
  final VoidCallback onViewRequests, onDonate;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final name =
        Get.find<SessionRepository>().displayName?.split(' ').first ?? '';
    final cities = <String, List<CharityCampaign>>{};
    for (final p in programmes) {
      cities.putIfAbsent(p.city, () => []).add(p);
    }
    return ColoredBox(
      color: AppColors.brand,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _DonorHomeHeader(
                greeting: name.isEmpty
                    ? 'Hi there!'.tr
                    : 'Hi @name!'.trParams({'name': name}),
                location: cities.isEmpty
                    ? 'Feed street animals, see every meal'.tr
                    : cities.keys.join(' · '),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceBase,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  MediaQuery.paddingOf(context).bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Section(
                      title: 'Cases you donate to it'.tr,
                      action: 'View all'.tr,
                      onTap: onViewRequests,
                    ),
                    const SizedBox(height: 16),
                    if (loadingRequests)
                      const HomeCaseShimmer()
                    else if (requests.isNotEmpty)
                      _HomeCase(
                        request: requests.first,
                        onTap: () => onOpenRequest(requests.first),
                      )
                    else
                      _DonorEmpty(
                        title: 'Your charity journey starts here'.tr,
                        body: 'Track your feeding requests and their proof'.tr,
                        onDonate: onDonate,
                      ),
                    if (error != null)
                      DonorLoadError(message: error!, onRetry: onRetry),
                    const SizedBox(height: 24),
                    _Section(title: 'Manage your Cities Program'.tr),
                    const SizedBox(height: 16),
                    if (loadingProgrammes)
                      const CityGridShimmer()
                    else
                      LayoutBuilder(
                        builder: (context, box) {
                          final columns = box.maxWidth >= 600 ? 3 : 2;
                          final width =
                              (box.maxWidth - (columns - 1) * 8) / columns;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            children: [
                              for (final entry in cities.entries)
                                SizedBox(
                                  width: width,
                                  child: _CityCard(
                                    city: entry.key,
                                    programme: entry.value.first,
                                    onTap: () => Get.toNamed(
                                      AppRoutes.charityAnimal,
                                      arguments: entry.value,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    if (!loadingProgrammes && cities.isEmpty)
                      Text(
                        'No feeding programmes are open right now.'.tr,
                        style: _muted,
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
}

class _HomeCase extends StatelessWidget {
  const _HomeCase({required this.request, required this.onTap});
  final DonationReceipt request;
  final VoidCallback onTap;
  int get step => switch (request.status) {
    DonationStatus.completed => 5,
    DonationStatus.feeding ||
    DonationStatus.proofSubmitted ||
    DonationStatus.proofRejected => 4,
    DonationStatus.accepted || DonationStatus.purchasing => 3,
    DonationStatus.assigned => 2,
    DonationStatus.reassignmentRequired => 1,
    DonationStatus.paid || DonationStatus.awaitingAssignment => 1,
    _ => 0,
  };
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: LocalOrNetworkImage(
                request.imageUrl ?? DonorArtwork.request(request),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: .42)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.campaignTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Meta(
                    icon: Iconsax.clock_copy,
                    text: donorDate(request.createdAt),
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  if (request.mealCount > 0)
                    _Meta(
                      icon: Iconsax.pet_copy,
                      text: '@count meals'.trParams({
                        'count': '${request.mealCount}',
                      }),
                      color: Colors.white,
                    ),
                  const SizedBox(height: 64),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Donate Status :'.tr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (var i = 0; i < 5; i++)
                              Expanded(
                                child: Container(
                                  height: 6,
                                  margin: EdgeInsetsDirectional.only(
                                    end: i == 4 ? 0 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: i < step
                                        ? AppColors.brand
                                        : AppColors.surfaceBase,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            request.label,
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CityCard extends StatelessWidget {
  const _CityCard({
    required this.city,
    required this.programme,
    required this.onTap,
  });
  final String city;
  final CharityCampaign programme;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 12,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: Image.asset(
            programme.isMakkah ? DonorArtwork.makkah : DonorArtwork.madinah,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text('Manage your Activity'.tr, style: _muted),
              const SizedBox(height: 8),
              Text(
                'Explore →'.tr,
                style: const TextStyle(
                  color: AppColors.brand,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DonorRequestsView extends StatefulWidget {
  const DonorRequestsView({
    super.key,
    required this.requests,
    required this.loading,
    required this.onRefresh,
    required this.onOpen,
    required this.onDonate,
    this.onLoadMore,
    this.loadingMore = false,
    this.error,
  });
  final List<DonationReceipt> requests;
  final bool loading, loadingMore;
  final Future<void> Function() onRefresh;
  final ValueChanged<DonationReceipt> onOpen;
  final VoidCallback onDonate;
  final VoidCallback? onLoadMore;
  final String? error;
  @override
  State<DonorRequestsView> createState() => _DonorRequestsViewState();
}

class _DonorRequestsViewState extends State<DonorRequestsView> {
  bool _largeCards = false;
  @override
  Widget build(BuildContext context) => DonorPage(
    onRefresh: widget.onRefresh,
    children: [
      Row(
        children: [
          Expanded(child: Text('Your Requests'.tr, style: _title)),
          IconButton(
            tooltip: (_largeCards ? 'List view' : 'Card view').tr,
            onPressed: () => setState(() => _largeCards = !_largeCards),
            icon: Icon(
              _largeCards ? Icons.view_list_outlined : Icons.grid_view_rounded,
              size: 19,
              color: AppColors.brand,
            ),
          ),
        ],
      ),
      Text('Track your feeding requests and their proof'.tr, style: _muted),
      const SizedBox(height: 16),
      if (widget.error != null)
        DonorLoadError(message: widget.error!, onRetry: widget.onRefresh),
      if (widget.loading)
        const RequestListShimmer()
      else if (widget.requests.isEmpty)
        _DonorEmpty(
          title: 'No requests yet'.tr,
          body: 'Your charity journey starts here'.tr,
          onDonate: widget.onDonate,
        )
      else
        for (final request in widget.requests)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DonorRequestCard(
              request: request,
              large: _largeCards,
              onTap: () => widget.onOpen(request),
            ),
          ),
      if (widget.loadingMore)
        const RequestListShimmer(count: 1)
      else if (widget.onLoadMore != null)
        TextButton(onPressed: widget.onLoadMore, child: Text('Load more'.tr)),
    ],
  );
}

class DonorRequestCard extends StatelessWidget {
  const DonorRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.large = false,
  });
  final DonationReceipt request;
  final VoidCallback onTap;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                request.reference,
                style: _muted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(child: DonationStatusBadge(request: request)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          request.campaignTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            if (request.packageName.isNotEmpty)
              _Meta(icon: Iconsax.box_copy, text: request.packageName),
            _Meta(icon: Iconsax.dollar_circle_copy, text: request.amountLabel),
          ],
        ),
        if (request.impact.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            request.impact,
            style: const TextStyle(
              color: AppColors.brand,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 6),
        _Meta(icon: Iconsax.calendar_copy, text: donorDate(request.createdAt)),
      ],
    );
    return SurfaceCard(
      radius: 14,
      shadow: true,
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    height: 145,
                    child: LocalOrNetworkImage(
                      request.imageUrl ?? DonorArtwork.request(request),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                text,
                const SizedBox(height: 12),
                PillButton(
                  label: 'Show Details'.tr,
                  height: 34,
                  onPressed: onTap,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 84,
                    height: 118,
                    child: LocalOrNetworkImage(
                      request.imageUrl ?? DonorArtwork.request(request),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: text),
              ],
            ),
    );
  }
}

class DonationStatusBadge extends StatelessWidget {
  const DonationStatusBadge({super.key, required this.request});
  final DonationReceipt request;
  @override
  Widget build(BuildContext context) {
    final color = request.status.isCompleted
        ? const Color(0xFF15C777)
        : request.status.isFinal
        ? AppColors.accent
        : request.status == DonationStatus.assigned
        ? const Color(0xFFEA29B9)
        : AppColors.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        request.label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class DonorImpactView extends StatefulWidget {
  const DonorImpactView({
    super.key,
    required this.requests,
    required this.loading,
    required this.onRefresh,
    required this.onOpen,
    required this.onDonate,
    this.error,
  });
  final List<DonationReceipt> requests;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<DonationReceipt> onOpen;
  final VoidCallback onDonate;
  final String? error;
  @override
  State<DonorImpactView> createState() => _DonorImpactViewState();
}

class _DonorImpactViewState extends State<DonorImpactView> {
  final Map<String, CharityRequestDetail> _details = {};
  String _signature = '';
  bool _loadingProofs = false;
  String? _proofError;
  @override
  void initState() {
    super.initState();
    _loadProofs();
  }

  @override
  void didUpdateWidget(covariant DonorImpactView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadProofs();
  }

  Future<void> _loadProofs({bool force = false}) async {
    final completed = widget.requests
        .where((r) => r.status.isCompleted)
        .toList();
    final signature = completed.map((r) => r.requestId).join('|');
    if (!force && signature == _signature) return;
    _signature = signature;
    if (completed.isEmpty) {
      _details.clear();
      return;
    }
    setState(() {
      _loadingProofs = true;
      _proofError = null;
    });
    try {
      final details = await Future.wait([
        for (final r in completed)
          Get.find<CharityRepository>().getRequestDetail(r),
      ]);
      if (!mounted || signature != _signature) return;
      setState(() {
        _details
          ..clear()
          ..addEntries(details.map((d) => MapEntry(d.request.requestId, d)));
      });
    } catch (_) {
      if (mounted) {
        setState(() => _proofError = 'Could not load verified feedings.'.tr);
      }
    } finally {
      if (mounted) setState(() => _loadingProofs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.requests
        .where((r) => r.status.isCompleted)
        .toList();
    return DonorPage(
      onRefresh: () async {
        await widget.onRefresh();
        await _loadProofs(force: true);
      },
      children: [
        Text('My Impact'.tr, style: _title),
        const SizedBox(height: 6),
        Text('See the difference your donations make'.tr, style: _muted),
        const SizedBox(height: 16),
        if (widget.loading)
          const ImpactSummaryShimmer()
        else
          Row(
            children: [
              _Stat(
                value: '${widget.requests.length}',
                label: 'Requests'.tr,
                icon: Iconsax.receipt_2_copy,
                color: AppColors.brand,
              ),
              const SizedBox(width: 8),
              _Stat(
                value:
                    '${widget.requests.fold<int>(0, (a, r) => a + r.mealCount)}',
                label: 'Meals'.tr,
                icon: Iconsax.box_copy,
                color: const Color(0xFFFFB900),
              ),
              const SizedBox(width: 8),
              _Stat(
                value: '${completed.length}',
                label: 'Completed'.tr,
                icon: Icons.check_circle_outline,
                color: const Color(0xFF15C777),
              ),
            ],
          ),
        const SizedBox(height: 20),
        _Section(title: 'Verified Feedings'.tr),
        const SizedBox(height: 16),
        if (widget.error != null)
          DonorLoadError(message: widget.error!, onRetry: widget.onRefresh),
        if (_proofError != null)
          DonorLoadError(
            message: _proofError!,
            onRetry: () => _loadProofs(force: true),
          ),
        if (widget.loading || _loadingProofs)
          const VerifiedFeedingListShimmer()
        else if (_details.values.where((d) => d.proof != null).isEmpty)
          _DonorEmpty(
            title: 'Proof you can see'.tr,
            body:
                'Once a feeding round is approved, its photos and details appear here.'
                    .tr,
            onDonate: widget.onDonate,
          )
        else
          for (final request in completed)
            if (_details[request.requestId]?.proof != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: VerifiedFeedingCard(
                  detail: _details[request.requestId]!,
                  onTap: () => widget.onOpen(request),
                ),
              ),
      ],
    );
  }
}

class VerifiedFeedingCard extends StatelessWidget {
  const VerifiedFeedingCard({
    super.key,
    required this.detail,
    required this.onTap,
  });
  final CharityRequestDetail detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final proof = detail.proof!;
    final photo = proof.media
        .where((m) => !m.isVideo || m.thumbnailUrl != null)
        .firstOrNull;
    return SurfaceCard(
      radius: 13,
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo != null)
            SizedBox(
              height: 145,
              child: LocalOrNetworkImage(photo.thumbnailUrl ?? photo.url),
            )
          else
            Container(
              height: 145,
              color: AppColors.brandSoft,
              child: const Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.brand,
                size: 32,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        detail.request.campaignTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusTag(
                      label: 'Verified'.tr,
                      foreground: const Color(0xFF15C777),
                      background: const Color(0xFFD9F7E7),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Meta(
                  icon: Iconsax.clock_copy,
                  text: donorDate(proof.approvedAt),
                ),
                const SizedBox(height: 6),
                _Meta(icon: Iconsax.location_copy, text: proof.approximateZone),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.fieldBorder),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBase,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Row(
                    children: [
                      _ProofStat(
                        value: '${proof.mealCount}',
                        label: 'Meals'.tr,
                      ),
                      _ProofStat(
                        value:
                            '${(proof.foodQuantityGrams / 1000).toStringAsFixed(1)} kg',
                        label: 'Food Usage'.tr,
                      ),
                      _ProofStat(
                        value: '${proof.animalsFedEstimate}',
                        label: 'Animals'.tr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PillButton(
                  label: 'View Feeding Details'.tr,
                  height: 36,
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofStat extends StatelessWidget {
  const _ProofStat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value, label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    ),
  );
}

class DonorProfileView extends StatefulWidget {
  const DonorProfileView({
    super.key,
    required this.onViewRequests,
    required this.onRefresh,
  });
  final VoidCallback onViewRequests;
  final Future<void> Function() onRefresh;
  @override
  State<DonorProfileView> createState() => _DonorProfileViewState();
}

class _DonorProfileViewState extends State<DonorProfileView> {
  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionRepository>();
    final name = session.displayName ?? 'My Profile'.tr;
    return DonorPage(
      onRefresh: widget.onRefresh,
      children: [
        SurfaceCard(
          radius: 14,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: AppColors.brandSoft,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.brand, fontSize: 25),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(session.email ?? '', style: _muted),
                    InkWell(
                      onTap: () async {
                        await Get.toNamed(AppRoutes.profileDetails);
                        if (mounted) setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Edit Profile'.tr,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'My Activity'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: Iconsax.box_copy,
              title: 'My Requests'.tr,
              subtitle: 'Track your requests'.tr,
              onTap: widget.onViewRequests,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Account & Settings'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: Iconsax.notification_copy,
              title: 'Notifications'.tr,
              onTap: () =>
                  Get.to(() => const DonorNotificationSettingsScreen()),
            ),
            _MenuRow(
              icon: Iconsax.global_copy,
              title: 'Language & Region'.tr,
              onTap: () => Get.to(() => const DonorLanguageScreen()),
            ),
            _MenuRow(
              icon: Iconsax.message_question_copy,
              title: 'Help & Support'.tr,
              onTap: () => Get.to(() => const DonorHelpScreen()),
            ),
            _MenuRow(
              icon: Iconsax.document_text_copy,
              title: 'Privacy & Terms'.tr,
              onTap: () => Get.to(() => const DonorPrivacyScreen()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Other'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        _MenuGroup(
          children: [
            _MenuRow(
              icon: Iconsax.logout_copy,
              title: 'Logout'.tr,
              onTap: ShellRouter.signOut,
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 9,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, indent: 35, color: AppColors.fieldBorder),
          children[i],
        ],
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: _muted),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 19,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: _title)),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Text(
            action!,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
    ],
  );
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
    this.color = const Color(0xFF92959B),
  });
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(text, style: TextStyle(color: color, fontSize: 13)),
      ),
    ],
  );
}

class _DonorEmpty extends StatelessWidget {
  const _DonorEmpty({
    required this.title,
    required this.body,
    required this.onDonate,
  });
  final String title, body;
  final VoidCallback onDonate;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    radius: 14,
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        const Icon(
          Icons.favorite_border_rounded,
          color: AppColors.brand,
          size: 35,
        ),
        const SizedBox(height: 12),
        Text(title, style: _title, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(body, style: _muted, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        PillButton(
          label: 'Feed street animals'.tr,
          height: 38,
          onPressed: onDonate,
        ),
      ],
    ),
  );
}

class DonorLoadError extends StatelessWidget {
  const DonorLoadError({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      children: [
        Text(message, style: _muted, textAlign: TextAlign.center),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: Text('Try again'.tr)),
      ],
    ),
  );
}

class _DonorHomeHeader extends StatelessWidget {
  const _DonorHomeHeader({required this.greeting, required this.location});
  final String greeting, location;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: ClipRect(
      child: CustomPaint(
        painter: const _DonorContours(),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: BrandWordmark(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const NotificationBell(),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        greeting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const AssetIcon(AppIcons.waveHand, size: 23),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Iconsax.location_copy,
                      color: Color(0xFFCEF0EE),
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFCEF0EE),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DonorContours extends CustomPainter {
  const _DonorContours();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.brand);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65;
    for (var x = -size.width; x < size.width * 2; x += 17) {
      canvas.drawPath(
        Path()
          ..moveTo(x, -10)
          ..cubicTo(
            x + 80,
            size.height * .3,
            x - 150,
            size.height * .45,
            x - 70,
            size.height * .75,
          )
          ..cubicTo(
            x - 30,
            size.height * .92,
            x - 50,
            size.height,
            x - 80,
            size.height + 20,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
