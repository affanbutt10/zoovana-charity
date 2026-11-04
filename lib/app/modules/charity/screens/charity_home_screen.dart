import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/zoovana_ui.dart';
import '../../../routes/app_routes.dart';
import '../controllers/charity_home_controller.dart';
import 'charity_setup_screens.dart';

class CharityHomeScreen extends GetView<CharityHomeController> {
  const CharityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZoovanaAppBar(title: 'Impact Charity hub'),
      extendBody: true,
      bottomNavigationBar: const CharityNavBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          22,
          20,
          AppBottomNav.contentPadding(context),
        ),
        children: staggered([
          const Text.rich(
            TextSpan(
              text: 'Give ',
              children: [
                TextSpan(
                  text: 'Love',
                  style: TextStyle(color: AppColors.accent),
                ),
                TextSpan(text: ', Change '),
                TextSpan(
                  text: 'Lives',
                  style: TextStyle(color: AppColors.accent),
                ),
              ],
            ),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          const Text(
            'Help animals in need find care, safety, and a loving home.',
            style: TextStyle(fontSize: 13.5),
          ),
          const SizedBox(height: 18),
          CharityOptionCard(
            image: AppAssets.charitySupport,
            title: 'Support and donation',
            body: 'Help stray animals get the food, medical care, and rescue support they need.',
            onTap: () => Get.toNamed(AppRoutes.charitySupport),
          ),
          const SizedBox(height: 18),
          CharityOptionCard(
            image: AppAssets.charityAdopt,
            title: 'Adopt Animals',
            body: 'Give an animal a loving home. Explore pets waiting for a family to call their own.',
            onTap: () => Get.toNamed(AppRoutes.adoption),
          ),
        ]),
      ),
    );
  }
}
