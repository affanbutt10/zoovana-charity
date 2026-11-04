import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/services/app_locale.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/models/charity_request_detail.dart';
import '../../../data/models/donation_receipt.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_state_view.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../charity/screens/charity_setup_screens.dart';
import '../../charity/widgets/animal_visual.dart';
import '../controllers/request_details_controller.dart';
import 'donation_history_screen.dart';

String _formatDateTime(DateTime date) =>
    '${date.day} ${AppLocale.shortMonth(date.month)}, '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

const _metaStyle = TextStyle(
  fontFamily: AppTheme.secondaryFontFamily,
  fontSize: 12,
  color: Color(0xFF8E8E8E),
);

/// A charity request's status, step-by-step progress with the operator's
/// photos, and the verified proof once it is approved.
class RequestDetailsScreen extends GetView<RequestDetailsController> {
  const RequestDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RequestDetailsController>(
      builder: (controller) {
        final detail = controller.detail;
        return Scaffold(
          appBar: ZoovanaAppBar(title: 'Request details'.tr),
          body: AppStateView(
            isLoading: controller.isLoading,
            error: controller.error,
            onRetry: controller.load,
            child: detail == null
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    color: AppColors.brand,
                    onRefresh: controller.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: staggered([
                        _SummaryCard(detail: detail),
                        if (detail.request.dedication.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DedicationCard(text: detail.request.dedication),
                        ],
                        const SizedBox(height: 22),
                        SectionHeader(
                          title: 'Progress'.tr,
                          action: 'Refresh'.tr,
                          onAction: controller.load,
                        ),
                        const SizedBox(height: 11),
                        _Timeline(detail: detail),
                        if (detail.proof != null) ...[
                          const SizedBox(height: 22),
                          SectionHeader(title: 'Verified proof'.tr),
                          const SizedBox(height: 11),
                          _ProofSection(proof: detail.proof!),
                        ],
                        if (controller.canCancel) ...[
                          const SizedBox(height: 22),
                          if (controller.canPay) ...[
                            PillButton(
                              label: 'Complete test payment'.tr,
                              onPressed: controller.pay,
                            ),
                            const SizedBox(height: 12),
                          ],
                          PillButton(
                            label: 'Cancel request'.tr,
                            style: PillButtonStyle.muted,
                            isLoading: controller.isCancelling,
                            onPressed: () =>
                                _confirmCancel(context, controller),
                          ),
                        ],
                      ]),
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
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Keep it'.tr),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Cancel request'.tr),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await controller.cancel();
}

/// Request overview on the white swirl card used for programmes.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.detail});
  final CharityRequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final request = detail.request;
    final bird = request.animalKind == AnimalKind.bird;
    final dog = request.animalKind == AnimalKind.dog;
    final skyline = citySkyline(request.city);
    final expected = detail.expectedCompletionAt;
    final verifiedAt = detail.proof?.approvedAt;
    final (footIcon, footText, footColor) = verifiedAt != null
        ? (
            Iconsax.tick_circle_copy,
            'Completed on @date'.trParams({
              'date': _formatDateTime(verifiedAt),
            }),
            const Color(0xFF2BB673),
          )
        : expected != null
        ? (
            Iconsax.clock_copy,
            'Expected by @date'.trParams({'date': _formatDateTime(expected)}),
            AppColors.brand,
          )
        : (null, '', AppColors.brand);
    return SurfaceCard(
      radius: 16,
      shadow: true,
      child: SizedBox(
        height: 176,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: CardSwirlPainter()),
            if (skyline != null)
              PositionedDirectional(
                end: -24,
                top: 8,
                width: 150,
                child: Opacity(
                  opacity: .2,
                  child: Image.asset(skyline, fit: BoxFit.fitWidth),
                ),
              ),
            PositionedDirectional(
              end: bird ? -6 : 4,
              bottom: bird ? 12 : 0,
              width: bird ? 128 : (dog ? 94 : 112),
              child: Image.asset(
                animalArt(request.animalKind),
                fit: BoxFit.contain,
                alignment: AlignmentDirectional.bottomEnd,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 120, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DonationStatusPill(
                    status: request.status,
                    label: request.label,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    request.campaignTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${request.packageName} · ${request.amountLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${request.reference} · ${_formatDateTime(request.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _metaStyle,
                  ),
                  const Spacer(),
                  if (footIcon != null)
                    Row(
                      children: [
                        Icon(footIcon, size: 15, color: footColor),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            footText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: footColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DedicationCard extends StatelessWidget {
  const _DedicationCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Iconsax.heart_copy, size: 18, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

/// A donor-facing step and the request states that belong to it.
class _Stage {
  const _Stage(this.title, this.pending, this.statuses);

  /// Shown once the step has happened.
  final String title;

  /// Shown while the step is the one being worked on.
  final String pending;
  final Set<DonationStatus> statuses;
}

const _stages = [
  _Stage('Request placed', 'Waiting for payment', {
    DonationStatus.paid,
    DonationStatus.awaitingAssignment,
  }),
  _Stage('Operator assigned', 'Finding a local operator', {
    DonationStatus.assigned,
    DonationStatus.reassignmentRequired,
  }),
  _Stage('Food purchased', 'Operator is buying the food', {
    DonationStatus.accepted,
    DonationStatus.purchasing,
  }),
  _Stage('Feeding round', 'Feeding round coming up', {DonationStatus.feeding}),
  _Stage('Proof submitted', 'Waiting for the feeding photos', {
    DonationStatus.proofSubmitted,
    DonationStatus.proofRejected,
  }),
  _Stage('Feeding completed', 'Reviewing the proof', {
    DonationStatus.completed,
  }),
];

enum _StepState { done, current, upcoming }

class _Timeline extends StatelessWidget {
  const _Timeline({required this.detail});
  final CharityRequestDetail detail;

  @override
  Widget build(BuildContext context) {
    // The latest event of each step, or null when it has not happened yet.
    final events = <RequestEvent?>[
      for (final stage in _stages)
        detail.timeline.reversed
            .where((event) => stage.statuses.contains(event.status))
            .firstOrNull,
    ];
    // Steps with an event have happened; the first one without is in
    // progress unless the request was closed.
    final next = events.indexWhere((event) => event == null);
    final closed = detail.status.isFinal && !detail.status.isCompleted;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          for (var i = 0; i < _stages.length; i++)
            _TimelineStep(
              stage: _stages[i],
              event: events[i],
              media: [
                for (final event in detail.timeline)
                  if (_stages[i].statuses.contains(event.status))
                    ...event.media,
              ],
              state: events[i] != null
                  ? _StepState.done
                  : i == next && !closed
                  ? _StepState.current
                  : _StepState.upcoming,
              isLast: i == _stages.length - 1,
            ),
          if (closed) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This request was @status.'.trParams({
                      'status': detail.request.label.toLowerCase(),
                    }),
                    style: const TextStyle(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.stage,
    required this.event,
    required this.media,
    required this.state,
    required this.isLast,
  });

  final _Stage stage;
  final RequestEvent? event;
  final List<ProofMedia> media;
  final _StepState state;
  final bool isLast;

  Widget get _dot => switch (state) {
    _StepState.done => const CircleAvatar(
      radius: 12,
      backgroundColor: AppColors.brand,
      child: Icon(Icons.check_rounded, size: 15, color: Colors.white),
    ),
    _StepState.current => Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: const CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
    ),
    _StepState.upcoming => Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderStrong, width: 2),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final done = state == _StepState.done;
    final note = event?.note ?? '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                _dot,
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: done ? AppColors.brand : AppColors.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state == _StepState.current
                              ? stage.pending.tr
                              : stage.title.tr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: switch (state) {
                              _StepState.done => AppColors.textPrimary,
                              _StepState.current => AppColors.accent,
                              _StepState.upcoming => AppColors.textTertiary,
                            },
                          ),
                        ),
                      ),
                      if (event != null)
                        Text(_formatDateTime(event!.at), style: _metaStyle),
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      note,
                      style: const TextStyle(
                        fontFamily: AppTheme.secondaryFontFamily,
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (media.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MediaStrip(media: media),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Up to three square thumbnails; the third shows how many more there are.
class _MediaStrip extends StatelessWidget {
  const _MediaStrip({required this.media});
  final List<ProofMedia> media;

  @override
  Widget build(BuildContext context) {
    final shown = media.length > 3 ? 3 : media.length;
    return Row(
      children: [
        for (var i = 0; i < shown; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ProofGalleryViewer.open(context, media, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProofImage(media[i], thumbnail: true),
                    if (i == 2 && media.length > 3)
                      ColoredBox(
                        color: const Color(0x99000000),
                        child: Center(
                          child: Text(
                            '+${media.length - 3}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProofSection extends StatelessWidget {
  const _ProofSection({required this.proof});
  final DonationProof proof;

  String get _food {
    final grams = proof.foodQuantityGrams;
    if (grams < 1000) return '@value g'.trParams({'value': '$grams'});
    final kg = grams / 1000;
    return '@value kg'.trParams({
      'value': kg == kg.roundToDouble()
          ? kg.toStringAsFixed(0)
          : kg.toStringAsFixed(1),
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (proof.media.isNotEmpty) ...[
        _ProofGallery(media: proof.media),
        const SizedBox(height: 12),
      ],
      Row(
        children: [
          StatTile(
            label: 'Meals'.tr,
            value: '${proof.mealCount}',
            icon: Icons.restaurant_rounded,
            tint: AppColors.accent,
          ),
          const SizedBox(width: 10),
          StatTile(
            label: 'Food'.tr,
            value: _food,
            icon: Iconsax.bag_2_copy,
            tint: AppColors.brand,
          ),
          const SizedBox(width: 10),
          StatTile(
            label: 'Animals'.tr,
            value: '~${proof.animalsFedEstimate}',
            icon: Icons.pets_rounded,
            tint: const Color(0xFF2BB673),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoLine(icon: Iconsax.location_copy, text: proof.approximateZone),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Iconsax.shield_tick_copy,
              text: 'Verified on @date'.trParams({
                'date': _formatDateTime(proof.approvedAt),
              }),
            ),
            if (proof.feederNote.isNotEmpty) ...[
              const Divider(height: 24, color: Color(0xFFF0F2F5)),
              Text(
                'Note from the operator'.tr,
                style: const TextStyle(
                  color: AppColors.brand,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                proof.feederNote,
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.brand),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
    ],
  );
}

/// Swipeable proof photos with page dots; tapping opens them full screen.
class _ProofGallery extends StatefulWidget {
  const _ProofGallery({required this.media});
  final List<ProofMedia> media;

  @override
  State<_ProofGallery> createState() => _ProofGalleryState();
}

class _ProofGalleryState extends State<_ProofGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: media.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => ProofGalleryViewer.open(context, media, index),
                child: ProofImage(media[index]),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x8C000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: IgnorePointer(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        media[_page].caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    for (var i = 0; i < media.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsetsDirectional.only(start: 5),
                        width: i == _page ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? Colors.white
                              : const Color(0x80FFFFFF),
                          borderRadius: BorderRadius.circular(3),
                        ),
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

/// Network or bundled proof photo, covering its box.
class ProofImage extends StatelessWidget {
  const ProofImage(this.media, {super.key, this.thumbnail = false});
  final ProofMedia media;
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final url = thumbnail ? media.thumbnailUrl ?? media.url : media.url;
    const placeholder = ColoredBox(
      color: AppColors.surfaceSubtle,
      child: Center(
        child: Icon(Iconsax.gallery_copy, color: AppColors.textTertiary),
      ),
    );
    if (!media.isNetwork) return Image.asset(url, fit: BoxFit.cover);
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
      errorBuilder: (_, _, _) => placeholder,
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
    final media = widget.media;
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
                  child: media[index].isNetwork
                      ? Image.network(media[index].url, fit: BoxFit.contain)
                      : Image.asset(media[index].url, fit: BoxFit.contain),
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
