import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import 'mine_icon_tile.dart';
import 'mine_tone.dart';

/// One quick stat: a tinted disc, the [value] (scaled down to fit a narrow
/// phone at large text) and a grey [label]. The tile dips slightly on touch
/// and opens its screen.
class MineStatTile extends StatelessWidget {
  const MineStatTile({
    super.key,
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
    required this.onTap,
  });

  /// The value's text style, shared by every stat so the row lines up.
  static TextStyle get valueStyle => AppTextStyles.headingMedium.copyWith(
    fontWeight: AppTextStyles.bold,
    color: AppColors.primaryText,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  final IconData icon;
  final MineTone tone;
  final Widget value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s4,
            horizontal: AppSpacing.s2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MineIconTile(icon: icon, tone: tone, circle: true),
              const SizedBox(height: AppSpacing.s8),
              FittedBox(fit: BoxFit.scaleDown, child: value),
              const SizedBox(height: AppSpacing.s2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.labelGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
