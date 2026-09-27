import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import 'coupon_fade.dart';

/// Start side of a coupon ticket: the warm amber → orange gradient with a
/// soft highlight, the discount [amount] in big bold figures (counting up from 0
/// the first time it shows when [countsUp]) and the "OFF" caption. [faded]
/// paints it in the spent-coupon greys ([CouponFade]).
class CouponStub extends StatelessWidget {
  const CouponStub({
    super.key,
    required this.amount,
    this.countsUp = false,
    this.faded = false,
  });

  final double amount;
  final bool countsUp;
  final bool faded;

  static const List<Color> gradient = [
    AppColors.proAmber,
    AppColors.accent3,
    kHeroPillPin,
  ];
  static const double _highlightAlpha = 0.3;
  static final List<Color> _highlight = [
    AppColors.white.withValues(alpha: _highlightAlpha),
    AppColors.white.withValues(alpha: 0),
  ];
  static const double _highlightOverhang = -AppSpacing.s32;
  static const double _captionAlpha = 0.9;
  static final Color _caption = AppColors.white.withValues(
    alpha: _captionAlpha,
  );
  static const double _captionSpacing = AppSize.s1;

  /// [gradient] in the spent-coupon greys.
  static final List<Color> fadedGradient = CouponFade.all(
    gradient,
    faded: true,
  );
  static final List<Color> _fadedHighlight = CouponFade.all(
    _highlight,
    faded: true,
  );

  @override
  Widget build(BuildContext context) {
    final ink = CouponFade.of(AppColors.white, faded: faded);
    final digits = AppTextStyles.displayLarge.copyWith(
      fontSize: AppSize.font30,
      height: AppSize.lh1_1,
      fontWeight: AppTextStyles.bold,
      color: ink,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: faded ? fadedGradient : gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: _highlightOverhang,
            start: _highlightOverhang,
            child: ExcludeSemantics(
              child: SizedBox.square(
                dimension: AppSize.s100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: faded ? _fadedHighlight : _highlight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s10,
              vertical: AppSpacing.s12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        Formatters.currency,
                        style: AppTextStyles.subheadingSmall.copyWith(
                          color: ink,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      CountUpText(
                        value: amount,
                        from: countsUp ? 0 : null,
                        maxLines: 1,
                        format: Formatters.amount,
                        style: digits,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'coupons.off'.tr(),
                  maxLines: 1,
                  style: AppTextStyles.subheadingSmall.copyWith(
                    color: CouponFade.of(_caption, faded: faded),
                    fontWeight: AppTextStyles.bold,
                    letterSpacing: _captionSpacing,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
