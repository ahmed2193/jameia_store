import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// White rounded card holding one group of profile fields, floating off the
/// page on a soft, diffuse shadow.
class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({super.key, required this.children});

  static const List<BoxShadow> _shadow = [
    BoxShadow(
      color: AppColors.shadowInk10,
      offset: Offset(0, AppSpacing.s4),
      blurRadius: AppSize.s16,
      spreadRadius: -AppSpacing.s6,
    ),
  ];

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.r2)),
        boxShadow: _shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
