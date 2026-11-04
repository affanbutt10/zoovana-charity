import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoovana_charity/app/core/services/cache_service.dart';
import 'package:zoovana_charity/app/data/datasources/charity_data_source.dart';
import 'package:zoovana_charity/app/data/models/charity_package.dart';
import 'package:zoovana_charity/app/data/repositories/charity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a created request is listed in history', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cache = CacheService(preferences);
    final repository = CharityRepository(SeedCharityDataSource(cache), cache);

    final campaign = (await repository.getCampaigns()).first;
    final package = (await repository.getPackages(campaign.id)).first;
    final receipt = await repository.createRequest(
      campaign: campaign,
      package: package,
      donor: const DonorDetails(
        fullName: 'Sara Ahmed',
        email: 'sara@example.com',
        phoneNumber: '+923001234567',
        dedication: 'For every animal in need',
      ),
    );

    final history = repository.getDonationHistory();
    expect(history, hasLength(1));
    expect(history.single.reference, receipt.reference);
    expect(history.single.campaignId, campaign.id);
    expect(history.single.dedication, 'For every animal in need');
    expect(history.single.amount, package.price);

    final refreshed = await repository.refreshDonationHistory();
    expect(refreshed.single.reference, receipt.reference);

    await repository.clearCache();
    expect(repository.getDonationHistory(), isEmpty);
  });
}
