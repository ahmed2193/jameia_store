import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';
import 'jameia_segmented_control.dart';

/// One label of a [JameiaSegmentedControl]: see-through, so the control's
/// sliding thumb shows beneath it. Its label (and the optional [icon] before
/// it) cross-fades to the chosen colours when the thumb sits under it: white
/// on the dark thumb, a bold deep-green label and a green icon on the
/// brand-soft thumb. The colours change even under reduced motion; only the
/// fade is skipped.
class JameiaSegment extends StatelessWidget {
  const JameiaSegment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone = JameiaSegmentTone.dark,
    this.icon,
  });

  static const double iconSize = AppSize.s18;

  final String label;
  final bool selected;

  /// `null` = disabled.
  final VoidCallback? onTap;
  final JameiaSegmentTone tone;

  /// A glyph before the label (decorative: the label is the name).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.fast);
    final soft = tone == JameiaSegmentTone.brandSoft;
    final chosenInk = soft ? AppColors.brandDeep : AppColors.white;
    final style = AppTextStyles.headingSmall.copyWith(
      fontWeight: soft && !selected ? AppTextStyles.medium : AppTextStyles.bold,
      color: selected ? chosenInk : AppColors.primaryText,
    );
    final glyph = icon;
    final iconInk = selected
        ? (soft ? AppColors.primary : AppColors.white)
        : AppColors.primaryText;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (glyph != null) ...[
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: iconInk),
                    duration: duration,
                    curve: AppMotion.signature,
                    builder: (context, color, _) =>
                        Icon(glyph, size: iconSize, color: color),
                  ),
                  const SizedBox(width: AppSpacing.s6),
                ],
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: AppMotion.signature,
                    style: style,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
