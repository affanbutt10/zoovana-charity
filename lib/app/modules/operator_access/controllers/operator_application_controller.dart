import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/errors/app_error_mapper.dart';
import '../../../data/models/charity_campaign.dart';
import '../../../data/models/feeder_models.dart';
import '../../../data/repositories/charity_repository.dart';
import '../../../data/repositories/feeder_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../routes/shell_router.dart';

/// KYC documents the application uploads.
enum KycDocument {
  idFront('Government ID (front)'),
  idBack('Government ID (back)'),
  selfie('Selfie holding your ID');

  const KycDocument(this._label);
  final String _label;

  /// Translated display text.
  String get label => _label.tr;
}

class OperatorApplicationController extends GetxController {
  OperatorApplicationController({
    required this.charity,
    required this.feeder,
    required this.session,
  });

  final CharityRepository charity;
  final FeederRepository feeder;
  final SessionRepository session;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final holderController = TextEditingController();
  final bankController = TextEditingController();
  final ibanController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;
  String? loadError;
  String? submitError;
  Map<String, String> fieldErrors = const {};

  List<CharityCampaign> programs = const [];
  CharityCampaign? program;
  List<FeederZone> zones = const [];
  final selectedZones = <String>{};
  int dailyCapacity = 3;
  final documents = <KycDocument, String>{};

  @override
  void onInit() {
    super.onInit();
    nameController.text = session.displayName ?? '';
    emailController.text = session.email ?? '';
    load();
  }

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    update();
    try {
      programs = await charity.getCampaigns();
      if (programs.isNotEmpty) await selectProgram(programs.first);
    } catch (error) {
      loadError = AppErrorMapper.map(error).message;
    }
    isLoading = false;
    update();
  }

  Future<void> selectProgram(CharityCampaign value) async {
    program = value;
    selectedZones.clear();
    zones = const [];
    update();
    try {
      zones = await feeder.getZones(value.id);
    } catch (_) {
      // Zones are optional; the reviewer can assign them.
    }
    update();
  }

  void toggleZone(String id) {
    selectedZones.contains(id)
        ? selectedZones.remove(id)
        : selectedZones.add(id);
    update();
  }

  void setCapacity(int value) {
    dailyCapacity = value.clamp(1, 100);
    update();
  }

  void setDocument(KycDocument document, String path) {
    documents[document] = path;
    update();
  }

  String? _missing() {
    if (program == null) return 'Choose the programme you will feed for.'.tr;
    if (nameController.text.trim().isEmpty) return 'Enter your full name.'.tr;
    if (phoneController.text.trim().length < 8) {
      return 'Enter a valid phone number.'.tr;
    }
    if (holderController.text.trim().isEmpty ||
        bankController.text.trim().isEmpty ||
        ibanController.text.trim().length < 15) {
      return 'Enter your bank details and a valid IBAN.'.tr;
    }
    for (final document in KycDocument.values) {
      if (!documents.containsKey(document)) {
        return 'Add the @document.'.trParams({'document': document.label});
      }
    }
    return null;
  }

  Future<void> submit() async {
    final missing = _missing();
    if (missing != null) {
      submitError = missing;
      update();
      return;
    }
    isSubmitting = true;
    submitError = null;
    fieldErrors = const {};
    update();
    try {
      await feeder.apply(
        FeederApplication(
          programId: program!.id,
          fullName: nameController.text.trim(),
          phoneNumber: phoneController.text.trim(),
          email: emailController.text.trim(),
          zoneIds: selectedZones.toList(),
          bankAccountHolderName: holderController.text.trim(),
          bankName: bankController.text.trim(),
          iban: ibanController.text.replaceAll(' ', '').toUpperCase(),
          dailyCapacity: dailyCapacity,
          idFrontPath: documents[KycDocument.idFront]!,
          idBackPath: documents[KycDocument.idBack]!,
          selfiePath: documents[KycDocument.selfie]!,
        ),
      );
      ShellRouter.open(await session.reload());
    } catch (error) {
      final mapped = AppErrorMapper.map(error);
      isSubmitting = false;
      fieldErrors = mapped.fieldErrors;
      submitError = mapped.message;
      update();
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    holderController.dispose();
    bankController.dispose();
    ibanController.dispose();
    super.onClose();
  }
}
