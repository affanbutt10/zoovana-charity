import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/services/app_locale.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/charity_request_detail.dart';
import '../../../data/models/charity_package.dart';
import '../../../data/models/donation_receipt.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/donor_shimmers.dart';
import '../../../shared/widgets/media_picker.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../charity/widgets/feeding_design_widgets.dart';
import '../../home/screens/donor_tab_views.dart';
import '../controllers/request_details_controller.dart';

String _dateTime(DateTime? date) => date == null
    ? 'Not available'.tr
    : '${date.day} ${AppLocale.shortMonth(date.month)} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class RequestDetailsScreen extends GetView<RequestDetailsController> {
  const RequestDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => GetBuilder<RequestDetailsController>(
    builder: (c) => Scaffold(
      appBar: ZoovanaAppBar(title: 'Request Details'.tr),
      body: AppStateView(
        isLoading: c.isLoading,
        loadingChild: const RequestDetailsShimmer(),
        error: c.error,
        onRetry: c.load,
        child: c.detail == null
            ? const SizedBox.shrink()
            : RefreshIndicator(
                onRefresh: c.load,
                child: RequestDetailsContent(
                  detail: c.detail!,
                  actions: c.canCancel
                      ? [
                          if (c.canPay) ...[
                            PillButton(
                              label: 'Continue payment'.tr,
                              onPressed: c.pay,
                            ),
                            const SizedBox(height: 12),
                          ],
                          PillButton(
                            label: 'Cancel request'.tr,
                            style: PillButtonStyle.muted,
                            isLoading: c.isCancelling,
                            onPressed: () => _confirmCancel(context, c),
                          ),
                        ]
                      : const [],
                ),
              ),
      ),
    ),
  );
}

/// Both reference states share the hero and information/items cards. Approved
/// proof selects the completed summary/gallery; pending requests show progress.
class RequestDetailsContent extends StatelessWidget {
  const RequestDetailsContent({
    super.key,
    required this.detail,
    this.actions = const [],
  });
  final CharityRequestDetail detail;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final request = detail.request;
    final proof = detail.proof;
    final completed = request.status.isCompleted || proof != null;
    final cover = proof?.media
        .where((m) => !m.isVideo || m.thumbnailUrl != null)
        .firstOrNull;
    final feedingAt = detail.feedingAt;
    final items = detail.items.isNotEmpty
        ? detail.items
        : [
            RequestFeedingItem(
              name: request.packageName,
              unitAmount: request.amount,
              currency: request.currency,
              quantity: 1,
            ),
          ];
    final notes = detail.feedingNotes.isNotEmpty
        ? detail.feedingNotes
        : proof?.feederNote ?? '';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: LocalOrNetworkImage(
            cover?.thumbnailUrl ??
                cover?.url ??
                request.imageUrl ??
                DonorArtwork.request(request),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      request.campaignTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: proof != null
                        ? StatusTag(
                            label: 'Verified'.tr,
                            foreground: const Color(0xFF15C777),
                            background: const Color(0xFFD9F7E7),
                          )
                        : DonationStatusBadge(request: request),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Iconsax.calendar_copy,
                    size: 17,
                    color: Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _dateTime(request.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (completed) ...[
                FeedingSectionCard(
                  title: 'Feeding Summary',
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBase,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF0EEE7)),
                      ),
                      child: Row(
                        children: [
                          _Metric(
                            value: proof?.mealCount?.toString() ?? '—',
                            label: 'Meals',
                          ),
                          _Metric(
                            value: proof?.foodQuantityGrams == null
                                ? '—'
                                : '${formatAmount(proof!.foodQuantityGrams! / 1000)} kg',
                            label: 'Food Usage',
                          ),
                          _Metric(
                            value: proof?.animalsFedEstimate?.toString() ?? '—',
                            label: 'Animals',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FeedingSectionCard(
                title: 'Feeding Information',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      FeedingInfoRow(
                        label: 'Feeding ID :',
                        value: request.reference,
                      ),
                      FeedingInfoRow(
                        label: 'Feeding Date :',
                        value: _dateTime(feedingAt),
                      ),
                      FeedingInfoRow(
                        label: 'Location :',
                        value: detail.zoneName?.isNotEmpty == true
                            ? detail.zoneName!
                            : proof?.approximateZone.isNotEmpty == true
                            ? proof!.approximateZone
                            : request.city,
                      ),
                      if (!completed &&
                          !request.status.isFinal &&
                          (detail.progress?.estimatedCompletionAt ??
                                  detail.expectedCompletionAt ??
                                  request.expectedCompletionAt) !=
                              null)
                        FeedingInfoRow(
                          label: 'Expected Date :',
                          value: _dateTime(
                            detail.progress?.estimatedCompletionAt ??
                                detail.expectedCompletionAt ??
                                request.expectedCompletionAt,
                          ),
                          highlight: true,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FeedingSectionCard(
                title: completed ? 'Donation Items :' : 'Feeding Items',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                  child: Column(
                    children: [
                      for (final item in items)
                        FeedingItemRow(
                          name: item.name,
                          description: item.description,
                          image: item.imageUrl ?? AppAssets.feedingCatFood,
                          quantity: item.quantity,
                          amount: item.unitAmount == null
                              ? '—'
                              : formatMoney(item.unitAmount!, item.currency),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (completed)
                FeedingSectionCard(
                  title: 'Feeding Photos & Videos :',
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _ProofGrid(media: proof?.media ?? const []),
                  ),
                )
              else ...[
                FeedingSectionCard(
                  title: 'Feeding Notes',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 78),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notes.isEmpty ? 'No notes'.tr : notes,
                            style: const TextStyle(
                              fontFamily: AppTheme.secondaryFontFamily,
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                          if (request.dedication.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Donor dedication'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.dedication,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FeedingSectionCard(
                  title: 'Feeding Progress',
                  child: _FeedingProgress(detail: detail),
                ),
              ],
              if (completed && notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...actions,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label.tr,
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

const _stages = [
  (
    'Request Placed',
    {
      DonationStatus.draft,
      DonationStatus.paymentPending,
      DonationStatus.paid,
      DonationStatus.awaitingAssignment,
    },
  ),
  ('Operator Assigned', {DonationStatus.assigned}),
  (
    'Operators Buying the Food',
    {DonationStatus.accepted, DonationStatus.purchasing},
  ),
  ('Feeding Round', {DonationStatus.feeding}),
  (
    'Proof Submitted',
    {DonationStatus.proofSubmitted, DonationStatus.proofRejected},
  ),
  ('Feeding Completed', {DonationStatus.completed}),
];

class _FeedingProgress extends StatelessWidget {
  const _FeedingProgress({required this.detail});
  final CharityRequestDetail detail;
  @override
  Widget build(BuildContext context) {
    final progress = detail.progress;
    if (progress != null) {
      return Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            for (var i = 0; i < progress.stages.length; i++)
              _ProgressRow(
                title: progress.stages[i].label,
                done: progress.stages[i].state == 'done',
                active: progress.stages[i].state == 'current',
                last: i == progress.stages.length - 1,
                time: progress.stages[i].state == 'done'
                    ? progress.stages[i].occurredAt
                    : null,
              ),
            if (progress.estimatedCompletionAt != null &&
                progress.haltedStatus == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Expected by @date'.trParams({
                    'date': _dateTime(progress.estimatedCompletionAt),
                  }),
                ),
              ),
            if (progress.haltedStatus != null) Text(detail.request.label),
          ],
        ),
      );
    }
    final events = [
      for (final stage in _stages)
        detail.timeline.reversed
            .where((e) => stage.$2.contains(e.status))
            .firstOrNull,
    ];
    final closed = detail.status.isFinal;
    final next = detail.status == DonationStatus.reassignmentRequired
        ? 1
        : events.indexWhere((e) => e == null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 16, 13, 14),
      child: Column(
        children: [
          for (var i = 0; i < _stages.length; i++)
            _ProgressRow(
              title: _stages[i].$1,
              done:
                  events[i] != null &&
                  !(detail.status == DonationStatus.reassignmentRequired &&
                      i == 1),
              active: !closed && i == next,
              last: i == _stages.length - 1,
              time: events[i]?.at,
              expected: i == _stages.length - 1
                  ? detail.expectedCompletionAt
                  : null,
            ),
          if (closed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                detail.request.label,
                style: const TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.title,
    required this.done,
    required this.active,
    required this.last,
    this.time,
    this.expected,
  });
  final String title;
  final bool done, active, last;
  final DateTime? time, expected;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 16,
          child: Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.accent : Colors.white,
                  border: Border.all(
                    color: done || active
                        ? AppColors.accent
                        : const Color(0xFFEDEDE8),
                    width: active ? 2 : 1,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: SizedBox(
                    width: 1,
                    child: CustomPaint(
                      painter: _DottedLine(
                        color: done
                            ? AppColors.accent
                            : const Color(0xFFEDEDE8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: done || active
                          ? AppColors.textPrimary
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    time != null
                        ? 'Time: @time'.trParams({'time': _time(time!)})
                        : expected != null
                        ? 'Expected: @time'.trParams({'time': _time(expected!)})
                        : '—',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DottedLine extends CustomPainter {
  const _DottedLine({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 2.0; y < size.height; y += 5) {
      canvas.drawLine(Offset(.5, y), Offset(.5, y + 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLine oldDelegate) =>
      oldDelegate.color != color;
}

class _ProofGrid extends StatelessWidget {
  const _ProofGrid({required this.media});
  final List<ProofMedia> media;
  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: 8),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBase,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Photos and videos are not available yet.'.tr,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: media.length > 6 ? 6 : media.length,
      itemBuilder: (context, index) {
        final more = index == 5 && media.length > 6;
        return Semantics(
          button: true,
          label: more
              ? '+${media.length - 5} ${'more'.tr}'
              : media[index].caption,
          child: InkWell(
            onTap: () => ProofGalleryViewer.open(context, media, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: more
                  ? ColoredBox(
                      color: AppColors.accent,
                      child: Center(
                        child: Text(
                          '+${media.length - 5} ${'more'.tr}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        ProofImage(media[index], thumbnail: true),
                        if (media[index].isVideo)
                          const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 29,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _confirmCancel(
  BuildContext context,
  RequestDetailsController controller,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cancel this request?'.tr),
      content: Text('It hasn’t been paid, so nothing will be charged.'.tr),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Keep it'.tr),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Cancel request'.tr),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await controller.cancel();
}

class ProofImage extends StatelessWidget {
  const ProofImage(
    this.media, {
    super.key,
    this.thumbnail = false,
    this.fit = BoxFit.cover,
  });
  final ProofMedia media;
  final bool thumbnail;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = thumbnail ? media.thumbnailUrl ?? media.url : media.url;
    const placeholder = ColoredBox(
      color: AppColors.surfaceSubtle,
      child: Center(
        child: Icon(Iconsax.gallery_copy, color: AppColors.textTertiary),
      ),
    );
    if (!media.isNetwork) return Image.asset(url, fit: fit);
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (_, error, _) {
        if (Get.isRegistered<RequestDetailsController>() &&
            error is NetworkImageLoadException &&
            (error.statusCode == 401 || error.statusCode == 404)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => Get.find<RequestDetailsController>().refreshFailedMedia(url),
          );
        }
        return placeholder;
      },
    );
  }
}

/// Full-screen, zoomable proof photos.
class ProofGalleryViewer extends StatefulWidget {
  const ProofGalleryViewer({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  final List<ProofMedia> media;
  final int initialIndex;

  static Future<void> open(
    BuildContext context,
    List<ProofMedia> media,
    int initialIndex,
  ) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          ProofGalleryViewer(media: media, initialIndex: initialIndex),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  State<ProofGalleryViewer> createState() => _ProofGalleryViewerState();
}

class _ProofGalleryViewerState extends State<ProofGalleryViewer> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<RequestDetailsController>()) {
      return GetBuilder<RequestDetailsController>(
        autoRemove: false,
        builder: (c) => _gallery(
          context,
          c.detail?.proof?.media.isNotEmpty == true
              ? c.detail!.proof!.media
              : widget.media,
        ),
      );
    }
    return _gallery(context, widget.media);
  }

  Widget _gallery(BuildContext context, List<ProofMedia> media) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: media.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: media[index].isVideo
                      ? _VideoPreview(media: media[index])
                      : ProofImage(media[index], fit: BoxFit.contain),
                ),
              ),
            ),
            PositionedDirectional(
              top: 8,
              start: 8,
              end: 16,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Close'.tr,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1} / ${media.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            if (media[_page].caption.isNotEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Text(
                  media[_page].caption,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.media});
  final ProofMedia media;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      if (media.thumbnailUrl != null) ProofImage(media, thumbnail: true),
      FilledButton.icon(
        onPressed: () async {
          final uri = Uri.tryParse(media.url);
          if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
            final opened = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            if (!opened) {
              Get.snackbar('Video'.tr, 'Unable to open this video.'.tr);
            }
          }
        },
        icon: const Icon(Icons.play_arrow),
        label: Text('Play video'.tr),
      ),
    ],
  );
}
