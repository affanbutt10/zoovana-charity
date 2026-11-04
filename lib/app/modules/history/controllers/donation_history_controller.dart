import 'package:get/get.dart';

import '../../../data/models/donation_receipt.dart';
import '../../../data/repositories/charity_repository.dart';

class DonationHistoryController extends GetxController {
  DonationHistoryController({required this.repository});

  final CharityRepository repository;
  List<DonationReceipt> receipts = const [];

  @override
  void onInit() {
    super.onInit();
    receipts = repository.getDonationHistory();
  }
}
