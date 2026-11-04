import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/services/app_locale.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/charity_repository.dart';
import '../../routes/app_routes.dart';

/// Bottom sheet to switch between English, Arabic and Urdu.
Future<void> showLanguagePicker(BuildContext context) async {
  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Text(
                'Language'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            for (final MapEntry(key: code, value: name)
                in AppLocale.names.entries)
              ListTile(
                title: Text(name, style: const TextStyle(fontSize: 16)),
                trailing: code == AppLocale.code
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () => Navigator.of(context).pop(code),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked != null && picked != AppLocale.code) {
    await AppLocale.change(picked);
    // Programme, package and status text come from the API in the app
    // language, so drop the cached requests and start again from the
    // splash to reload them.
    if (Get.isRegistered<CharityRepository>()) {
      await Get.find<CharityRepository>().clearCache();
    }
    Get.offAllNamed<void>(AppRoutes.splash);
  }
}

/// Small pill showing the current language; opens the picker.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: () => showLanguagePicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.global_copy, size: 16, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(
              AppLocale.names[AppLocale.code]!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
