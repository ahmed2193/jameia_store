import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';

/// Small white disc with a pencil on the avatar's bottom-end corner: the
/// header opens the profile editor.
class MineAvatarEditBadge extends StatelessWidget {
  const MineAvatarEditBadge({super.key});

  static const double _size = AppSize.s24;
  static const double _glyph = AppSize.s13;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.low,
      ),
      child: const Icon(
        HeroIcons.edit,
        size: _glyph,
        color: AppColors.primaryText,
      ),
    );
  }
}
