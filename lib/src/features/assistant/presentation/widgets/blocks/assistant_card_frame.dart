import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The white card every block sits in: an optional icon + title, then the
/// content. The border tweens (a proposal turns green once confirmed).
class AssistantCardFrame extends StatelessWidget {
  const AssistantCardFrame({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.borderColor = AppColors.divider,
    this.padding = defaultPadding,
    this.transparent = false,
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

  @override
  Widget build(BuildContext context) {
    final heading = title;
    final glyph = icon;
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
                  Icon(glyph, size: AppSize.s18, color: AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.s6),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(heading, style: AppTextStyles.headingSmall),
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
