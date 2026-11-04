import '../../../apis/core/api_response.dart';
import '../datasources/feeder_data_source.dart';
import '../models/feeder_models.dart';

/// Operator (feeder) operations. Every task action returns the updated task;
/// callers replace their copy with it.
class FeederRepository {
  FeederRepository(this._dataSource);

  final FeederDataSource _dataSource;

  /// Latest profile, for the header and profile tab.
  FeederProfile? profile;

  Future<List<FeederZone>> getZones(String programId) =>
      _dataSource.fetchZones(programId);

  Future<FeederProfile> apply(FeederApplication application) async =>
      profile = await _dataSource.apply(application);

  Future<FeederProfile> getProfile() async =>
      profile = await _dataSource.fetchProfile();

  Future<FeederProfile> setAvailability({
    bool? isAvailable,
    int? dailyCapacity,
  }) async => profile = await _dataSource.updateProfile(
    isAvailable: isAvailable,
    dailyCapacity: dailyCapacity,
  );

  Future<FeederDashboard> getDashboard() => _dataSource.fetchDashboard();

  Future<PagedList<FeederTask>> getTasks(TaskTab tab, {int page = 1}) =>
      _dataSource.fetchTasks(statuses: tab.statuses, page: page);

  Future<FeederTask> getTask(String assignmentId) =>
      _dataSource.fetchTask(assignmentId);

  Future<FeederTask> accept(String assignmentId) =>
      _dataSource.accept(assignmentId);

  Future<FeederTask> decline(String assignmentId, String reason) =>
      _dataSource.decline(assignmentId, reason);

  Future<FeederTask> startPurchasing(String assignmentId) =>
      _dataSource.setStatus(assignmentId, TaskAction.purchasing);

  Future<FeederTask> startFeeding(String assignmentId) =>
      _dataSource.setStatus(assignmentId, TaskAction.feeding);

  Future<TaskMedia> uploadMedia(
    String assignmentId, {
    required String filePath,
    required TaskMediaType type,
    DateTime? capturedAt,
  }) => _dataSource.uploadMedia(
    assignmentId,
    filePath: filePath,
    type: type,
    capturedAt: capturedAt,
  );

  Future<FeederTask> deleteMedia(String assignmentId, String mediaId) =>
      _dataSource.deleteMedia(assignmentId, mediaId);

  Future<FeederTask> submitProof(String assignmentId, ProofSubmission proof) =>
      _dataSource.submitProof(assignmentId, proof);

  Future<PagedList<FeederPayout>> getPayouts({String? status, int page = 1}) =>
      _dataSource.fetchPayouts(status: status, page: page);

  void clear() => profile = null;
}
