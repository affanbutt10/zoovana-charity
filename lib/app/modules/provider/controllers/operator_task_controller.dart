import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/app_error_mapper.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/media_expiry.dart';
import '../../../data/models/feeder_models.dart';
import '../../../data/repositories/feeder_repository.dart';
import '../../../routes/app_routes.dart';

/// A file in the proof grid: uploading, uploaded, or failed with a retry.
class ProofUpload {
  ProofUpload({required this.path, required this.type});

  final String path;
  final TaskMediaType type;
  TaskMedia? media;
  String? error;

  bool get isUploading => media == null && error == null;
}

/// One operator task. Buttons come only from `allowed_actions`, and every
/// action's response replaces the local task.
class OperatorTaskController extends GetxController with MediaExpiryRefresh {
  OperatorTaskController({required this.repository, required this.location});

  final FeederRepository repository;
  final LocationService location;

  String? assignmentId;
  FeederTask? task;
  bool isLoading = true;
  String? error;

  /// The action whose request is in flight.
  String? busyAction;

  /// Shown after a successful accept, before the operator opens the task.
  bool showAccepted = false;

  /// Local "on the way" step between buying and feeding. Never sent.
  bool onTheWay = false;

  /// Files picked on this screen that aren't on the server task yet.
  final uploads = <ProofUpload>[];
  final mealsController = TextEditingController();
  final animalsController = TextEditingController();
  final noteController = TextEditingController();
  final receiptController = TextEditingController();
  String? proofError;

  static const maxFiles = 8;

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    switch (argument) {
      case FeederTask value:
        assignmentId = value.id;
        _apply(value);
        isLoading = false;
        load();
      case String id when id.isNotEmpty:
        assignmentId = id;
        load();
      default:
        isLoading = false;
        error = 'This task could not be found.'.tr;
    }
  }

  void _apply(FeederTask value) {
    final previous = task;
    task = value;
    refreshBeforeExpiry([
      for (final media in [
        ...value.pendingMedia,
        ...?value.latestProof?.media,
        ...?value.previousProof?.media,
      ])
        media.expiresAt,
    ], load);
    if (previous == null || previous.id != value.id) {
      mealsController.text = '${value.mealCount}';
    }
    if (value.status != TaskStatus.purchasing) onTheWay = false;
  }

  /// Uploaded media: the server's pending files, then this screen's uploads.
  List<TaskMedia> get pendingMedia {
    final server = task?.pendingMedia ?? const <TaskMedia>[];
    final known = {for (final media in server) media.id};
    return [
      ...server,
      for (final upload in uploads)
        if (upload.media != null && !known.contains(upload.media!.id))
          upload.media!,
    ];
  }

  List<ProofUpload> get activeUploads => [
    for (final upload in uploads)
      if (upload.media == null) upload,
  ];

  int get fileCount => pendingMedia.length + activeUploads.length;

  Future<void> load() async {
    final id = assignmentId;
    if (id == null) return;
    isLoading = task == null;
    error = null;
    update();
    try {
      _apply(await repository.getTask(id));
    } catch (exception) {
      if (_leaveIfGone(exception)) return;
      error = AppErrorMapper.map(exception).message;
    }
    isLoading = false;
    update();
  }

  /// `task_not_found` and `task_not_assigned_to_user` mean the link is stale
  /// or the task moved to another operator.
  bool _leaveIfGone(Object exception) {
    final mapped = AppErrorMapper.map(exception);
    final gone =
        mapped.hasCode(ApiErrorCode.taskNotFound) ||
        mapped.hasCode(ApiErrorCode.taskNotAssignedToUser);
    if (!gone) return false;
    Get.offNamed<void>(AppRoutes.providerJobs);
    Get.snackbar('Task unavailable'.tr, mapped.message);
    return true;
  }

  Future<void> _run(
    String action,
    Future<FeederTask> Function(String id) call,
  ) async {
    final id = assignmentId;
    if (id == null || busyAction != null) return;
    busyAction = action;
    update();
    try {
      _apply(await call(id));
      if (action == TaskAction.accept) showAccepted = true;
    } catch (exception) {
      if (!_leaveIfGone(exception)) {
        final mapped = AppErrorMapper.map(exception);
        Get.snackbar('Task'.tr, mapped.message);
        // The task changed on the server; redraw from the latest copy.
        if (mapped.statusCode == 409) await load();
      }
    }
    busyAction = null;
    update();
  }

  Future<void> accept() => _run(TaskAction.accept, repository.accept);

  Future<void> decline(String reason) =>
      _run(TaskAction.decline, (id) => repository.decline(id, reason));

  Future<void> startPurchasing() =>
      _run(TaskAction.purchasing, repository.startPurchasing);

  Future<void> startFeeding() =>
      _run(TaskAction.feeding, repository.startFeeding);

  void markOnTheWay() {
    onTheWay = true;
    update();
  }

  void openTask() {
    showAccepted = false;
    update();
  }

  Future<void> addFile(String path, TaskMediaType type) async {
    if (fileCount >= maxFiles) {
      proofError = 'A proof can have up to @max files. Remove one first.'
          .trParams({'max': '$maxFiles'});
      update();
      return;
    }
    final upload = ProofUpload(path: path, type: type);
    uploads.add(upload);
    proofError = null;
    update();
    await _upload(upload);
  }

  Future<void> retry(ProofUpload upload) async {
    upload.error = null;
    update();
    await _upload(upload);
  }

  void discard(ProofUpload upload) {
    uploads.remove(upload);
    update();
  }

  Future<void> _upload(ProofUpload upload) async {
    final id = assignmentId;
    if (id == null) return;
    try {
      upload.media = await repository.uploadMedia(
        id,
        filePath: upload.path,
        type: upload.type,
        capturedAt: await _capturedAt(upload.path),
      );
    } catch (exception) {
      final mapped = AppErrorMapper.map(exception);
      upload.error = switch (mapped.code) {
        ApiErrorCode.mediaTooLarge => 'Too large (max @size).'.trParams({
          'size': _megabytes(mapped),
        }),
        ApiErrorCode.unsupportedMediaType =>
          'This file type isn’t supported.'.tr,
        ApiErrorCode.mediaLimitExceeded => 'Too many files. Remove some.'.tr,
        ApiErrorCode.mediaStorageUnavailable =>
          'Upload unavailable. Retry later.'.tr,
        _ => mapped.message,
      };
      if (mapped.hasCode(ApiErrorCode.invalidStateTransition)) await load();
    }
    update();
  }

  static String _megabytes(AppError error) {
    final bytes = error.details['max_bytes'];
    return bytes is num
        ? '${(bytes / (1024 * 1024)).round()} MB'
        : 'the limit'.tr;
  }

  static Future<DateTime?> _capturedAt(String path) async {
    try {
      return await File(path).lastModified();
    } catch (_) {
      return null;
    }
  }

  Future<void> removeMedia(TaskMedia media) async {
    final id = assignmentId;
    if (id == null) return;
    try {
      _apply(await repository.deleteMedia(id, media.id));
      uploads.removeWhere((upload) => upload.media?.id == media.id);
    } catch (exception) {
      Get.snackbar('Remove file'.tr, AppErrorMapper.map(exception).message);
    }
    update();
  }

  Future<void> submitProof() async {
    final id = assignmentId;
    if (id == null || busyAction != null) return;
    if (activeUploads.any((upload) => upload.isUploading)) {
      proofError = 'Wait for the uploads to finish.'.tr;
      update();
      return;
    }
    final media = pendingMedia;
    if (!media.any((item) => item.type != TaskMediaType.receipt)) {
      proofError = 'Add at least one photo or video of the feeding.'.tr;
      update();
      return;
    }
    final meals = int.tryParse(mealsController.text.trim());
    final animals = int.tryParse(animalsController.text.trim());
    if (meals == null || meals <= 0 || animals == null || animals < 0) {
      proofError =
          'Enter the meals served and roughly how many animals ate.'.tr;
      update();
      return;
    }
    busyAction = TaskAction.submitProof;
    proofError = null;
    update();
    try {
      final fix = await location.current();
      _apply(
        await repository.submitProof(
          id,
          ProofSubmission(
            latitude: fix.latitude,
            longitude: fix.longitude,
            gpsAccuracyM: fix.accuracyM,
            mealCount: meals,
            animalsFedEstimate: animals,
            feederNote: noteController.text.trim(),
            receiptAmount: receiptController.text.trim(),
            mediaIds: [for (final item in media) item.id],
            fedAt: DateTime.now(),
            deviceMetadata: {
              'platform': Platform.operatingSystem,
              'os_version': Platform.operatingSystemVersion,
            },
          ),
        ),
      );
      uploads.clear();
    } catch (exception) {
      if (!_leaveIfGone(exception)) {
        final mapped = AppErrorMapper.map(exception);
        proofError = switch (mapped.code) {
          ApiErrorCode.gpsRequired =>
            'Allow location access so the feeding spot can be verified.'.tr,
          ApiErrorCode.gpsAccuracyUnacceptable =>
            'Your location isn’t accurate enough (needs @meters m). Move to '
                    'open sky and try again.'
                .trParams({
                  'meters': '${mapped.details['max_accuracy_m'] ?? 100}',
                }),
          ApiErrorCode.proofMediaRequired =>
            'Add at least one photo or video of the feeding.'.tr,
          _ => mapped.message,
        };
        if (mapped.statusCode == 409) await load();
      }
    }
    busyAction = null;
    update();
  }

  @override
  void onClose() {
    mealsController.dispose();
    animalsController.dispose();
    noteController.dispose();
    receiptController.dispose();
    super.onClose();
  }
}
