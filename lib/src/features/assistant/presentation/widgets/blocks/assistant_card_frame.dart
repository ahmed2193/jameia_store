import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The white card every block sits in: an optional icon + title, then the
/// content. The border tweens over `medium` (a proposal turns green once
/// confirmed); a [muted] card (a spent proposal) cross-fades its title and
/// icon to the muted palette over `fast` — colours only, so no opacity
/// layer is left behind.
class AssistantCardFrame extends StatelessWidget {
  const AssistantCardFrame({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.borderColor = AppColors.divider,
    this.padding = defaultPadding,
    this.transparent = false,
    this.muted = false,
  });

  static const EdgeInsetsGeometry defaultPadding = EdgeInsetsDirectional.all(
    AppSpacing.s12,
  );

  final Widget child;
  final String? title;
  final IconData? icon;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  /// The card sits on a white [Material] that paints the ink of a tappable
  /// card, so the frame itself must not cover it.
  final bool transparent;

  /// Spent: the heading in the muted palette.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    final glyph = icon;
    final fade = MotionGuard.duration(context, AppMotion.fast);
    final headingColor = muted
        ? AppColors.secondaryText
        : AppColors.primaryText;
    final glyphColor = muted ? AppColors.secondaryText : AppColors.primaryDark;
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.medium),
      curve: AppMotion.signature,
      padding: padding,
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (heading != null) ...[
            Row(
              children: [
                if (glyph != null) ...[
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: glyphColor),
                    duration: fade,
                    builder: (context, color, _) =>
                        Icon(glyph, size: AppSize.s18, color: color),
                  ),
                  const SizedBox(width: AppSpacing.s6),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: AnimatedDefaultTextStyle(
                      duration: fade,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: headingColor,
                      ),
                      child: Text(heading),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          child,
        ],
      ),
    );
  }
}
