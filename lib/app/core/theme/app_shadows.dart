import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x101D252D), blurRadius: 18, offset: Offset(0, 7)),
  ];

  static final brandGlow = <BoxShadow>[
    BoxShadow(
      color: AppColors.brand.withValues(alpha: 0.22),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}
