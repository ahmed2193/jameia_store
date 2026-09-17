import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// 50dp circular avatar with a white ring (bundle `gfb120`); the placeholder
/// glyph shows while the account has no picture (the API exposes none yet).
class MineAvatar extends StatelessWidget {
  const MineAvatar({super.key, this.url = ''});

  final String url;

  static const double _size = AppSize.s50;

  @override
  Widget build(BuildContext context) {
    // One-shot pop on mount — the avatar grows-in when the tab opens.
    return PopScale.onMount(
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: AppSize.s2),
        ),
        child: url.isEmpty
            ? const CircleAvatar(
                backgroundColor: AppColors.white,
                child: Icon(
                  JameiaIcons.merchant,
                  size: AppSize.s24,
                  color: AppColors.tertiaryText,
                ),
              )
            : JameiaImage.circle(url: url, size: _size),
      ),
    );
  }
}
