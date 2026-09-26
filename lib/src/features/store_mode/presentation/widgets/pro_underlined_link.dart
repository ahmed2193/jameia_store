import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';

/// The paywall's underlined text action ("Browse all brands", "Sign in",
/// "Terms apply"…), in [color] on any background. Presses in slightly on
/// touch; the tap target is at least 44 dp tall.
class ProUnderlinedLink extends StatelessWidget {
  const ProUnderlinedLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.primaryText,
    this.style,
  });

  static const double _minTarget = AppSize.s44;

  final String label;
  final VoidCallback onTap;
  final Color color;

  /// Defaults to [AppTextStyles.subheadingMedium].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    // Its own node (only the label and the tap), so the link flag and the tap
    // never merge into the section around it.
    return Semantics(
      container: true,
      link: true,
      child: PressScale(
        onTap: onTap,
        haptic: null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minTarget),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s4,
              ),
              child: Text(
                label,
                style: (style ?? AppTextStyles.subheadingMedium).copyWith(
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
