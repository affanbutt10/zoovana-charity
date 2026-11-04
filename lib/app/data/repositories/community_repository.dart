import 'package:shared_preferences/shared_preferences.dart';

class CommunityRepository {
  CommunityRepository(this._preferences);

  static const _applicationsKey = 'zoovana_adoption_applications_v1';
  static const _providerJobKey = 'zoovana_provider_job_completed_v1';
  final SharedPreferences _preferences;

  Set<String> getAdoptionApplications() =>
      (_preferences.getStringList(_applicationsKey) ?? const []).toSet();

  bool hasAppliedFor(String petName) =>
      getAdoptionApplications().contains(petName);

  Future<void> submitAdoptionApplication(String petName) async {
    final applications = getAdoptionApplications()..add(petName);
    await _preferences.setStringList(
      _applicationsKey,
      applications.toList()..sort(),
    );
  }

  bool get providerJobCompleted =>
      _preferences.getBool(_providerJobKey) ?? false;

  Future<void> completeProviderJob() =>
      _preferences.setBool(_providerJobKey, true);
}
