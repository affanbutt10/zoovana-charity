import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/app_locale.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/zoovana_ui.dart';

/// These preferences are device-local until a backend preference API exists.
class DonorNotificationSettingsScreen extends StatefulWidget {
  const DonorNotificationSettingsScreen({super.key});
  @override
  State<DonorNotificationSettingsScreen> createState() =>
      _DonorNotificationSettingsScreenState();
}

class _DonorNotificationSettingsScreenState
    extends State<DonorNotificationSettingsScreen> {
  static const _items = [
    (
      'request_updates',
      'Request updates',
      'Status, feeding and payment updates',
      Iconsax.calendar_copy,
    ),
    (
      'feeding_proof',
      'Feeding proof',
      'Photos and completed feedings',
      Iconsax.pet_copy,
    ),
    (
      'offers',
      'Offers',
      'Special offers, discounts and promotions',
      Iconsax.discount_shape_copy,
    ),
    (
      'charity',
      'Charity',
      'Feeding programmes and reminders',
      Iconsax.heart_copy,
    ),
  ];
  late final Map<String, bool> _enabled = {
    for (final item in _items)
      item.$1:
          Get.find<SharedPreferences>().getBool(
            'donor_notification_${item.$1}',
          ) ??
          (item.$1 == 'request_updates'),
  };
  Future<void> _save() async {
    final prefs = Get.find<SharedPreferences>();
    for (final item in _enabled.entries) {
      await prefs.setBool('donor_notification_${item.key}', item.value);
    }
    if (mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Notifications'.tr),
    bottomNavigationBar: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: PillButton(
        label: 'Save preferences'.tr,
        height: 48,
        fontSize: 14,
        onPressed: _save,
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        Text(
          'Notifications Settings'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose what you’d like to be notified about.'.tr,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 14,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 18),
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _NotificationPreferenceTile(
              key: ValueKey('notification_${item.$1}'),
              title: item.$2.tr,
              subtitle: item.$3.tr,
              icon: item.$4,
              enabled: _enabled[item.$1]!,
              onTap: () =>
                  setState(() => _enabled[item.$1] = !_enabled[item.$1]!),
            ),
          ),
        Text(
          'Saved on this device. Push notification preferences are not synced yet.'
              .tr,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

/// Matches the 78 px Figma tile at its normal text size; grows for larger
/// accessibility text rather than clipping the description.
class _NotificationPreferenceTile extends StatelessWidget {
  const _NotificationPreferenceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: enabled,
    label: '$title, $subtitle',
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 78),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 18, 14, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 19, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Container(
                      key: ValueKey('radio_$title'),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 1.5,
                          color: enabled
                              ? AppColors.brand
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                      child: enabled
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.brand,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DonorLanguageScreen extends StatefulWidget {
  const DonorLanguageScreen({super.key});
  @override
  State<DonorLanguageScreen> createState() => _DonorLanguageScreenState();
}

class _DonorLanguageScreenState extends State<DonorLanguageScreen> {
  String _language = AppLocale.code;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Language & Region'.tr),
    bottomNavigationBar: BottomActionBar(
      children: [
        PillButton(
          label: 'Save preferences'.tr,
          onPressed: () async {
            await AppLocale.change(_language);
            Get.back<void>();
          },
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Choose the language :'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        for (final entry in AppLocale.names.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SurfaceCard(
              radius: 9,
              onTap: () => setState(() => _language = entry.key),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.language, color: AppColors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(entry.value)),
                  Icon(
                    _language == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 19,
                    color: _language == entry.key
                        ? AppColors.brand
                        : AppColors.borderStrong,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Region & Currency :'.tr,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Prices and currencies are supplied by each feeding programme.'.tr,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );
}

class DonorHelpScreen extends StatelessWidget {
  const DonorHelpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Help & Support'.tr),
    bottomNavigationBar: BottomActionBar(
      children: [
        PillButton(
          label: 'Contact Support'.tr,
          onPressed: () => Get.to(() => const DonorContactScreen()),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SurfaceCard(
          radius: 12,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.support_agent, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(
                'How can we help?'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Find answers or contact our support team.'.tr,
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final item in [
          (
            'Requests & Payments',
            'Track your feeding requests in the Requests tab. Open a request to see its current status and payment details.',
          ),
          (
            'Feeding Proof',
            'Approved feeding photos and details appear in My Impact after review.',
          ),
          (
            'Account & Privacy',
            'Open Edit Profile to manage your name and account details.',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SurfaceCard(
              radius: 10,
              child: ExpansionTile(
                iconColor: AppColors.brand,
                leading: const Icon(
                  Icons.help_outline,
                  size: 20,
                  color: AppColors.accent,
                ),
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(item.$1.tr, style: const TextStyle(fontSize: 16)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    item.$2.tr,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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

class DonorContactScreen extends StatelessWidget {
  const DonorContactScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionRepository>();
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Contact Support'.tr),
      bottomNavigationBar: BottomActionBar(
        children: [PillButton(label: 'Submit Request'.tr, onPressed: null)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: BrandWordmark(light: false),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Contact us :'.tr,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Support requests are temporarily unavailable. Please try again later.'
                .tr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          for (final field in [
            ('Full Name', session.displayName ?? '', Icons.person_outline),
            ('Email Address', session.email ?? '', Icons.mail_outline),
            ('Phone Number', '', Icons.phone_outlined),
          ]) ...[
            Text('${field.$1.tr} *', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: field.$2,
              readOnly: true,
              decoration: InputDecoration(
                hintText: field.$1.tr,
                prefixIcon: Icon(field.$3, size: 18),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('Your Request *'.tr, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: true,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Enter Request'.tr,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DonorPrivacyScreen extends StatelessWidget {
  const DonorPrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ZoovanaAppBar(title: 'Privacy & Terms'.tr),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: BrandWordmark(light: false),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Privacy and Policy :'.tr,
          style: const TextStyle(color: AppColors.accent, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text('The published privacy policy is not available yet.'.tr),
        const SizedBox(height: 24),
        Text(
          'Terms and Conditions :'.tr,
          style: const TextStyle(color: AppColors.accent, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text('The published terms and conditions are not available yet.'.tr),
      ],
    ),
  );
}
