import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// "Show 9 more" / "Show less" under a folded item list: a full-width text
/// button whose chevron turns over when the list opens. It counts the rows it
/// hides, not the pieces (the store row above says how many items).
class OrderLinesToggle extends StatelessWidget {
  const OrderLinesToggle({
    super.key,
    required this.expanded,
    required this.hidden,
    required this.onPressed,
  });

  final bool expanded;

  /// Rows past the fold.
  final int hidden;
  final VoidCallback onPressed;

  /// Half a turn: the chevron points up once the list is open.
  static const double _openTurns = 0.5;

  @override
  Widget build(BuildContext context) {
    final label = expanded
        ? 'orders.show_less'.tr()
        : 'orders.show_more_lines'.tr(namedArgs: {'count': '$hidden'});
    return Semantics(
      button: true,
      expanded: expanded,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.chip)),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              vertical: AppSpacing.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.brandDeep,
                  ),
                ),
                const SizedBox(width: AppSpacing.s4),
                AnimatedRotation(
                  turns: expanded ? _openTurns : 0,
                  duration: MotionGuard.duration(context, AppMotion.medium),
                  curve: AppMotion.signature,
                  child: const HeroIcon(
                    HeroIcons.chevronDown,
                    size: AppSize.s20,
                    color: AppColors.brandDeep,
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
