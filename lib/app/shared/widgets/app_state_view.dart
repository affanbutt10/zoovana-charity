import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.error,
    this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.medium,
    switchInCurve: AppMotion.curve,
    switchOutCurve: AppMotion.curve,
    child: KeyedSubtree(
      key: ValueKey(
        isLoading
            ? 'loading'
            : error == null
            ? 'content'
            : 'error',
      ),
      child: _content(),
    ),
  );

  Widget _content() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.base),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: Text('Try again'.tr),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return child;
  }
}
