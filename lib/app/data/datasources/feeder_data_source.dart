import 'dart:io';

import 'package:dio/dio.dart';

import '../../../apis/core/api_client.dart';
import '../../../apis/core/api_endpoints.dart';
import '../../../apis/core/api_response.dart';
import '../../core/errors/app_error.dart';
import '../models/charity_session.dart';
import '../models/feeder_models.dart';

abstract interface class FeederDataSource {
  Future<List<FeederZone>> fetchZones(String programId);

  Future<FeederProfile> apply(FeederApplication application);

  Future<FeederProfile> fetchProfile();

  Future<FeederProfile> updateProfile({bool? isAvailable, int? dailyCapacity});

  Future<FeederDashboard> fetchDashboard();

  Future<PagedList<FeederTask>> fetchTasks({
    required List<String> statuses,
    int page = 1,
    int pageSize = 20,
  });

  Future<FeederTask> fetchTask(String assignmentId);

  Future<FeederTask> accept(String assignmentId);

  Future<FeederTask> decline(String assignmentId, String reason);

  /// Only `purchasing` and `feeding` can be set from the app.
  Future<FeederTask> setStatus(String assignmentId, String status);

  Future<TaskMedia> uploadMedia(
    String assignmentId, {
    required String filePath,
    required TaskMediaType type,
    DateTime? capturedAt,
  });

  Future<FeederTask> deleteMedia(String assignmentId, String mediaId);

  Future<FeederTask> submitProof(String assignmentId, ProofSubmission proof);

  Future<PagedList<FeederPayout>> fetchPayouts({String? status, int page = 1});
}

class RemoteFeederDataSource implements FeederDataSource {
  RemoteFeederDataSource(this._client);

  /// Videos above this go straight to storage instead of through the API.
  static const directUploadBytes = 25 * 1024 * 1024;

  final ApiClient _client;
  Dio get _dio => _client.feeding;

  static DioMediaType? _mediaType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => DioMediaType('image', 'jpeg'),
      'png' => DioMediaType('image', 'png'),
      'webp' => DioMediaType('image', 'webp'),
      'heic' => DioMediaType('image', 'heic'),
      'mp4' => DioMediaType('video', 'mp4'),
      'mov' => DioMediaType('video', 'quicktime'),
      _ => null,
    };
  }

  static Future<MultipartFile> _file(String path) => MultipartFile.fromFile(
    path,
    filename: path.split(Platform.pathSeparator).last,
    contentType: _mediaType(path),
  );

  @override
  Future<List<FeederZone>> fetchZones(String programId) async {
    final response = await _dio.get<dynamic>(FeedingEndpoints.zones(programId));
    return [for (final item in response.dataList) FeederZone.fromJson(item)];
  }

  @override
  Future<FeederProfile> apply(FeederApplication application) async {
    final form = FormData.fromMap({
      'program_id': application.programId,
      'full_name': application.fullName,
      'phone_number': application.phoneNumber,
      if (application.email != null && application.email!.isNotEmpty)
        'email': application.email,
      'zone_ids': application.zoneIds.join(','),
      'bank_account_holder_name': application.bankAccountHolderName,
      'bank_name': application.bankName,
      'iban': application.iban,
      'daily_capacity': application.dailyCapacity,
      'government_id_front': await _file(application.idFrontPath),
      'government_id_back': await _file(application.idBackPath),
      'selfie_with_id': await _file(application.selfiePath),
    });
    final response = await _dio.post<dynamic>(
      FeedingEndpoints.applyFeeder,
      data: form,
      options: ApiClient.upload,
    );
    return FeederProfile.fromJson(response.dataMap);
  }

  @override
  Future<FeederProfile> fetchProfile() async {
    final response = await _dio.get<dynamic>(FeedingEndpoints.feederMe);
    return FeederProfile.fromJson(response.dataMap);
  }

  @override
  Future<FeederProfile> updateProfile({
    bool? isAvailable,
    int? dailyCapacity,
  }) async {
    final response = await _dio.patch<dynamic>(
      FeedingEndpoints.feederMe,
      data: {'is_available': ?isAvailable, 'daily_capacity': ?dailyCapacity},
    );
    return FeederProfile.fromJson(response.dataMap);
  }

  @override
  Future<FeederDashboard> fetchDashboard() async {
    final response = await _dio.get<dynamic>(FeedingEndpoints.feederDashboard);
    return FeederDashboard.fromJson(response.dataMap);
  }

  @override
  Future<PagedList<FeederTask>> fetchTasks({
    required List<String> statuses,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.feederTasks,
      queryParameters: {
        'status': statuses.join(','),
        'page': page,
        'page_size': pageSize,
      },
    );
    return response.paged(FeederTask.fromJson);
  }

  Future<FeederTask> _task(Future<Response<dynamic>> call) async =>
      FeederTask.fromJson((await call).dataMap);

  @override
  Future<FeederTask> fetchTask(String assignmentId) =>
      _task(_dio.get<dynamic>(FeedingEndpoints.task(assignmentId)));

  @override
  Future<FeederTask> accept(String assignmentId) =>
      _task(_dio.post<dynamic>(FeedingEndpoints.acceptTask(assignmentId)));

  @override
  Future<FeederTask> decline(String assignmentId, String reason) => _task(
    _dio.post<dynamic>(
      FeedingEndpoints.declineTask(assignmentId),
      data: {'reason': reason},
    ),
  );

  @override
  Future<FeederTask> setStatus(String assignmentId, String status) => _task(
    _dio.post<dynamic>(
      FeedingEndpoints.taskStatus(assignmentId),
      data: {'status': status},
    ),
  );

  @override
  Future<TaskMedia> uploadMedia(
    String assignmentId, {
    required String filePath,
    required TaskMediaType type,
    DateTime? capturedAt,
  }) async {
    if (type == TaskMediaType.video &&
        await File(filePath).length() > directUploadBytes) {
      return _uploadDirect(assignmentId, filePath);
    }
    final form = FormData.fromMap({
      'file': await _file(filePath),
      'media_type': type.name,
      if (capturedAt != null)
        'captured_at': capturedAt.toUtc().toIso8601String(),
    });
    final response = await _dio.post<dynamic>(
      FeedingEndpoints.taskMedia(assignmentId),
      data: form,
      options: ApiClient.upload,
    );
    return TaskMedia.fromJson(response.dataMap);
  }

  /// Signed upload to Cloudinary, then registration with the API.
  Future<TaskMedia> _uploadDirect(String assignmentId, String filePath) async {
    final signature = (await _dio.get<dynamic>(
      FeedingEndpoints.taskUploadSignature(assignmentId),
      queryParameters: const {'resource_type': 'video'},
    )).dataMap;
    final uploadUrl =
        signature.strOrNull('upload_url') ??
        'https://api.cloudinary.com/v1_1/${signature.str('cloud_name')}/video/upload';
    const notFormFields = {'upload_url', 'cloud_name', 'resource_type'};
    final form = FormData.fromMap({
      for (final entry in signature.entries)
        if (!notFormFields.contains(entry.key) && entry.value != null)
          entry.key: '${entry.value}',
      'file': await _file(filePath),
    });
    final uploaded = await Dio(
      BaseOptions(
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
      ),
    ).post<dynamic>(uploadUrl, data: form);
    final publicId = (uploaded.data as Map)['public_id'];
    final response = await _dio.post<dynamic>(
      FeedingEndpoints.taskRegisterMedia(assignmentId),
      data: {
        'public_id': publicId,
        'media_type': 'video',
        'resource_type': 'video',
      },
    );
    return TaskMedia.fromJson(response.dataMap);
  }

  @override
  Future<FeederTask> deleteMedia(String assignmentId, String mediaId) => _task(
    _dio.delete<dynamic>(FeedingEndpoints.taskMediaItem(assignmentId, mediaId)),
  );

  @override
  Future<FeederTask> submitProof(String assignmentId, ProofSubmission proof) =>
      _task(
        _dio.post<dynamic>(
          FeedingEndpoints.taskProof(assignmentId),
          data: proof.toJson(),
        ),
      );

  @override
  Future<PagedList<FeederPayout>> fetchPayouts({
    String? status,
    int page = 1,
  }) async {
    final response = await _dio.get<dynamic>(
      FeedingEndpoints.feederPayouts,
      queryParameters: {'page': page, 'page_size': 20, 'status': ?status},
    );
    return response.paged(FeederPayout.fromJson);
  }
}

/// In-memory operator backend for demos and tests. It follows the guide's
/// state machine and `allowed_actions` table.
class SeedFeederDataSource implements FeederDataSource {
  SeedFeederDataSource({this.onApplied});

  /// Lets the seed session move to "under review" after an application.
  final Future<void> Function()? onApplied;

  static const _maxMedia = 8;
  var _mediaSeq = 0;

  FeederProfile _profile = const FeederProfile(
    id: 'demo-feeder',
    fullName: 'Ahmad Bahsas',
    phoneNumber: '+966 55 123 4567',
    email: 'operator@zoovana.demo',
    verificationStatus: VerificationStatus.approved,
    programs: ['Feed Cats in Makkah'],
    zones: [FeederZone(id: 'zone-aziziyah', name: 'Al-Aziziyah')],
    isAvailable: true,
    dailyCapacity: 5,
    tasksCompleted: 12,
    bankName: 'Al Rajhi Bank',
    ibanLastFour: '4421',
  );

  late final Map<String, FeederTask> _tasks = {
    for (final task in [
      _seedTask('task-1001', TaskStatus.pendingAcceptance, 'ZF-1001'),
      _seedTask('task-1002', TaskStatus.pendingAcceptance, 'ZF-1002'),
      _seedTask('task-1003', TaskStatus.purchasing, 'ZF-1003'),
      _seedTask(
        'task-1004',
        TaskStatus.proofRejected,
        'ZF-1004',
        rejection: 'Please upload a clearer feeding photo.',
      ),
      _seedTask('task-0990', TaskStatus.completed, 'ZF-0990'),
      _seedTask('task-0985', TaskStatus.declined, 'ZF-0985'),
    ])
      task.id: task,
  };

  static Set<String> _actionsFor(TaskStatus status, {DateTime? deadline}) =>
      switch (status) {
        TaskStatus.pendingAcceptance
            when deadline == null || deadline.isAfter(DateTime.now()) =>
          {TaskAction.accept, TaskAction.decline},
        TaskStatus.accepted => {TaskAction.decline, TaskAction.purchasing},
        TaskStatus.purchasing => {TaskAction.feeding},
        TaskStatus.feeding => {
          TaskAction.uploadMedia,
          TaskAction.deleteMedia,
          TaskAction.submitProof,
        },
        TaskStatus.proofRejected => {
          TaskAction.uploadMedia,
          TaskAction.deleteMedia,
          TaskAction.submitProof,
          TaskAction.feeding,
        },
        _ => const {},
      };

  FeederTask _seedTask(
    String id,
    TaskStatus status,
    String reference, {
    String? rejection,
  }) {
    final now = DateTime.now();
    final deadline = now.add(const Duration(hours: 23, minutes: 41));
    return FeederTask(
      id: id,
      requestId: 'req-$id',
      requestReference: reference,
      status: status,
      programName: 'Feed Cats in Makkah',
      cityName: 'Makkah',
      packageName: 'Mango Sunrise',
      mealCount: 50,
      foodQuantityGrams: 3000,
      foodBudget: '60.00',
      feederFee: '15.00',
      currency: 'SAR',
      zoneName: 'Al-Aziziyah',
      instructions: 'Feed near the approved zone and photograph the food and the animals.',
      assignedAt: now.subtract(const Duration(minutes: 19)),
      acceptDeadlineAt: deadline,
      expectedCompletionAt: now.add(const Duration(hours: 48)),
      completedAt: status == TaskStatus.completed ? now : null,
      allowedActions: _actionsFor(status, deadline: deadline),
      timeline: [
        TaskEvent(
          status: TaskStatus.pendingAcceptance,
          at: now.subtract(const Duration(minutes: 19)),
        ),
        if (status != TaskStatus.pendingAcceptance)
          TaskEvent(status: status, at: now),
      ],
      proofRejectionReason: rejection,
      canResubmit: rejection != null,
      previousProof: rejection == null
          ? null
          : TaskProof(
              id: 'proof-$id',
              reviewStatus: 'rejected',
              rejectionReason: rejection,
              media: const [
                TaskMedia(
                  id: 'old-1',
                  type: TaskMediaType.image,
                  url: 'assets/images/charity_street.jpg',
                ),
              ],
            ),
    );
  }

  FeederTask _get(String id) {
    final task = _tasks[id];
    if (task == null) {
      throw const AppError(
        type: AppErrorType.server,
        statusCode: 404,
        code: ApiErrorCode.taskNotFound,
        message: 'This task no longer exists.',
      );
    }
    return task;
  }

  Never _conflict(String code, String message) => throw AppError(
    type: AppErrorType.server,
    statusCode: 409,
    code: code,
    message: message,
  );

  FeederTask _move(FeederTask task, TaskStatus status) {
    final updated = task.copyWith(
      status: status,
      allowedActions: _actionsFor(status),
      timeline: [
        ...task.timeline,
        TaskEvent(status: status, at: DateTime.now()),
      ],
    );
    return _tasks[task.id] = updated;
  }

  @override
  Future<List<FeederZone>> fetchZones(String programId) async => const [
    FeederZone(id: 'zone-aziziyah', name: 'Al-Aziziyah'),
    FeederZone(id: 'zone-shisha', name: 'Al-Shisha'),
    FeederZone(id: 'zone-awali', name: 'Al-Awali'),
  ];

  @override
  Future<FeederProfile> apply(FeederApplication application) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await onApplied?.call();
    return _profile = FeederProfile(
      id: 'demo-feeder-review',
      fullName: application.fullName,
      phoneNumber: application.phoneNumber,
      verificationStatus: VerificationStatus.pendingReview,
      dailyCapacity: application.dailyCapacity,
    );
  }

  @override
  Future<FeederProfile> fetchProfile() async => _profile;

  @override
  Future<FeederProfile> updateProfile({
    bool? isAvailable,
    int? dailyCapacity,
  }) async => _profile = _profile.copyWith(
    isAvailable: isAvailable,
    dailyCapacity: dailyCapacity,
  );

  @override
  Future<FeederDashboard> fetchDashboard() async {
    int count(Iterable<String> codes) =>
        _tasks.values.where((task) => codes.contains(task.status.code)).length;
    return FeederDashboard(
      newTasks: count(TaskTab.newTasks.statuses),
      activeTasks: count(TaskTab.active.statuses),
      completedTasks: _profile.tasksCompleted,
      isAvailable: _profile.isAvailable,
      dailyCapacity: _profile.dailyCapacity,
      payoutsByCurrency: const {'SAR': '30.00'},
    );
  }

  @override
  Future<PagedList<FeederTask>> fetchTasks({
    required List<String> statuses,
    int page = 1,
    int pageSize = 20,
  }) async {
    final items = _tasks.values
        .where((task) => statuses.contains(task.status.code))
        .toList(growable: false);
    return PagedList(items, PageMeta(total: items.length));
  }

  @override
  Future<FeederTask> fetchTask(String assignmentId) async => _get(assignmentId);

  @override
  Future<FeederTask> accept(String assignmentId) async {
    final task = _get(assignmentId);
    if (task.status == TaskStatus.accepted) return task;
    if (!task.can(TaskAction.accept)) {
      _conflict(
        ApiErrorCode.acceptanceDeadlineExpired,
        'The time to accept this task has passed.',
      );
    }
    return _move(task, TaskStatus.accepted);
  }

  @override
  Future<FeederTask> decline(String assignmentId, String reason) async {
    final task = _get(assignmentId);
    if (task.status == TaskStatus.declined) return task;
    if (!task.can(TaskAction.decline)) {
      _conflict(ApiErrorCode.invalidStateTransition, 'This task changed.');
    }
    return _move(task, TaskStatus.declined);
  }

  @override
  Future<FeederTask> setStatus(String assignmentId, String status) async {
    final task = _get(assignmentId);
    if (task.status.code == status) return task;
    if (!task.can(status)) {
      _conflict(ApiErrorCode.invalidStateTransition, 'This task changed.');
    }
    return _move(task, TaskStatus.fromCode(status));
  }

  @override
  Future<TaskMedia> uploadMedia(
    String assignmentId, {
    required String filePath,
    required TaskMediaType type,
    DateTime? capturedAt,
  }) async {
    final task = _get(assignmentId);
    if (!task.can(TaskAction.uploadMedia)) {
      _conflict(ApiErrorCode.invalidStateTransition, 'This task changed.');
    }
    if (task.pendingMedia.length >= _maxMedia) {
      throw const AppError(
        type: AppErrorType.validation,
        statusCode: 400,
        code: ApiErrorCode.mediaLimitExceeded,
        message: 'A proof can have up to 8 files.',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final media = TaskMedia(
      id: 'media-${++_mediaSeq}',
      type: type,
      url: filePath,
      capturedAt: capturedAt,
    );
    _tasks[assignmentId] = task.copyWith(
      pendingMedia: [...task.pendingMedia, media],
    );
    return media;
  }

  @override
  Future<FeederTask> deleteMedia(String assignmentId, String mediaId) async {
    final task = _get(assignmentId);
    return _tasks[assignmentId] = task.copyWith(
      pendingMedia: [
        for (final media in task.pendingMedia)
          if (media.id != mediaId) media,
      ],
    );
  }

  @override
  Future<FeederTask> submitProof(
    String assignmentId,
    ProofSubmission proof,
  ) async {
    final task = _get(assignmentId);
    if (task.status == TaskStatus.proofSubmitted) return task;
    if (!task.can(TaskAction.submitProof)) {
      _conflict(ApiErrorCode.invalidStateTransition, 'This task changed.');
    }
    final ids = proof.mediaIds?.toSet();
    final attached = [
      for (final media in task.pendingMedia)
        if (ids == null || ids.contains(media.id)) media,
    ];
    if (!attached.any((media) => media.type != TaskMediaType.receipt)) {
      throw const AppError(
        type: AppErrorType.validation,
        statusCode: 400,
        code: ApiErrorCode.proofMediaRequired,
        message: 'Add at least one photo or video of the feeding.',
      );
    }
    if (proof.gpsAccuracyM > 100) {
      throw const AppError(
        type: AppErrorType.validation,
        statusCode: 400,
        code: ApiErrorCode.gpsAccuracyUnacceptable,
        message: 'Your location is not accurate enough.',
        details: {'max_accuracy_m': 100},
      );
    }
    final moved = _move(task, TaskStatus.proofSubmitted);
    return _tasks[assignmentId] = moved.copyWith(
      pendingMedia: const [],
      latestProof: TaskProof(
        id: 'proof-$assignmentId',
        reviewStatus: 'pending',
        media: attached,
      ),
    );
  }

  @override
  Future<PagedList<FeederPayout>> fetchPayouts({
    String? status,
    int page = 1,
  }) async {
    final now = DateTime.now();
    final items = [
      FeederPayout(
        id: 'payout-3',
        requestReference: 'ZF-0990',
        amount: '15.00',
        currency: 'SAR',
        status: PayoutStatus.eligible,
        eligibleAt: now.subtract(const Duration(days: 1)),
      ),
      FeederPayout(
        id: 'payout-2',
        requestReference: 'ZF-0971',
        amount: '15.00',
        currency: 'SAR',
        status: PayoutStatus.eligible,
        eligibleAt: now.subtract(const Duration(days: 3)),
      ),
      FeederPayout(
        id: 'payout-1',
        requestReference: 'ZF-0940',
        amount: '15.00',
        currency: 'SAR',
        status: PayoutStatus.paid,
        eligibleAt: now.subtract(const Duration(days: 12)),
        paidAt: now.subtract(const Duration(days: 8)),
      ),
    ].where((item) => status == null || item.status.name == status).toList();
    final totals = <String, double>{};
    for (final item in items) {
      totals[item.status.name] =
          (totals[item.status.name] ?? 0) + (double.tryParse(item.amount) ?? 0);
    }
    return PagedList(
      items,
      PageMeta(
        total: items.length,
        totals: {
          for (final entry in totals.entries)
            entry.key: {'SAR': entry.value.toStringAsFixed(2)},
        },
      ),
    );
  }
}
