import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'settings_icon_badge.dart';

/// Hairline between two rows of a settings card, starting under the row
/// labels (past the icon badge) like a grouped iOS / M3 list.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  static const double _indent =
      AppSpacing.s16 + SettingsIconBadge.defaultDimension + AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AppSize.s1,
      thickness: AppSize.s0_5,
      color: AppColors.overlayDivider,
      indent: _indent,
    );
  }
}
