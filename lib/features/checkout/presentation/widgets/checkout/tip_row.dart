import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/keeta_assets.dart';
import '../../../../../core/design/keeta_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';

/// Rider tip row: from css.json `c94bf8`/`f762c4`:
///   chip height 30dp, border-radius 10dp, padding 0 16dp,
///   selected bg #FFE41F, unselected bg #EBEBEB, gap 8dp.
class TipRow extends StatelessWidget {
  const TipRow({
    super.key,
    required this.selected,
    required this.options,
    required this.onSelect,
  });
  final double selected;
  final List<double> options;
  final ValueChanged<double> onSelect;

  /// One chip. The selected chip pops (`PopScale` re-fires on each new
  /// selection via [selected] as its key) and the fill/weight cross-fades via
  /// an [AnimatedContainer] over the [AppMotion.fast] token.
  Widget _buildChip(BuildContext context, double t, bool on) {
    final chip = AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      height: 30,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Real KeeTa: #FFE41F selected / #EBEBEB unselected
        color: on ? AppColors.primary : AppColors.divider,
        borderRadius: BorderRadius.circular(AppRadius.r5), // 10dp
      ),
      child: Text(
        t == 0 ? 'checkout.tip_none'.tr() : Formatters.price(t),
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: on ? AppTextStyles.bold : AppTextStyles.regular,
        ),
      ),
    );
    // Selected chip pops on selection; popKey = the active value so picking a
    // new chip re-fires the pop on the one that just became selected.
    return on ? PopScale(popKey: selected, child: chip) : chip;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s14,
      ),
      child: Row(
        children: [
          // Real KeeTa tips icon (icon_tips PNG) instead of a glyph
          Image.asset(
            KeetaAssets.iconTips,
            width: 20,
            height: 20,
            errorBuilder: (context, error, stackTrace) => const Icon(
              KeetaIcons.reward,
              size: 20,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Text('checkout.rider_tip'.tr(), style: AppTextStyles.bodyLarge),
          const SizedBox(width: AppSpacing.s8),
          // The chips carry full localized prices ("5.000 د.ك"), which are wide
          // in Arabic — let the group scroll horizontally instead of overflowing.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in options)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.s8,
                      ),
                      child: PressScale(
                        onTap: () => onSelect(t),
                        child: _buildChip(context, t, t == selected),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
