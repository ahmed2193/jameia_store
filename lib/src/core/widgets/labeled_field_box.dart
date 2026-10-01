import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';

/// A form field in the brand look: a bold [label] over a rounded box holding
/// the input ([child]). The box follows the field — a grey hairline at rest,
/// a brand-green ring while [focused], red on a pale red fill once [error]
/// is shown — and cross-fades between them ([AppMotion.fast]). The ring is
/// drawn over the box, never inside it, so [child] does not move when it
/// appears. A tap anywhere on the box calls [onTap] (focus the field).
class LabeledFieldBox extends StatelessWidget {
  const LabeledFieldBox({
    super.key,
    required this.label,
    required this.child,
    this.focused = false,
    this.error = false,
    this.onTap,
    this.height = AppSize.s56,
  });

  final String label;
  final Widget child;
  final bool focused;
  final bool error;
  final VoidCallback? onTap;
  final double height;

  static const double _hairline = AppSize.s1_5;
  static const double _ring = AppSize.s2;
  static const BorderRadius _corners = BorderRadius.all(
    Radius.circular(AppRadius.r4),
  );

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.fast);
    final ring = error
        ? AppColors.error
        : focused
        ? AppColors.primaryDark
        : AppColors.scrimTransparent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label,
        ),
        const SizedBox(height: AppSpacing.s8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.signature,
            height: height,
            decoration: BoxDecoration(
              color: error ? AppColors.errorBg : AppColors.white,
              borderRadius: _corners,
              border: Border.all(
                color: error ? AppColors.error : AppColors.disabledText,
                width: _hairline,
              ),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: _corners,
              border: Border.all(color: ring, width: _ring),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}
