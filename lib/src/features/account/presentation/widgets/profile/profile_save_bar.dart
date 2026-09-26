import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import 'profile_save_button.dart';

/// Solid white foot of the form holding the Save button (the coupon confirm
/// bar's shape: rounded top, a soft shadow cast upward). It sits under the
/// scrolling fields — above the keyboard while one is being edited — so Save
/// is always one tap away.
class ProfileSaveBar extends StatelessWidget {
  const ProfileSaveBar({super.key});

  static const BorderRadius _radius = BorderRadius.vertical(
    top: Radius.circular(AppRadius.r2),
  );
  static const List<BoxShadow> _lift = [
    BoxShadow(
      color: AppColors.shadowInk10,
      offset: Offset(0, -AppSpacing.s4),
      blurRadius: AppSpacing.s20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: _radius,
        boxShadow: _lift,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s12,
        ),
        child: ProfileSaveButton(),
      ),
    );
  }
}
