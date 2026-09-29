import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/cart_offers_view.dart';
import 'cart_deal_icon.dart';
import 'cart_deal_pointer_painter.dart';
import 'cart_deal_texts.dart';

/// One offer of the "Buy more, save more" sheet: its glyph and name, and
/// under it what it saved ("Offer applied. KD 2.000 saved!") or what is
/// still missing ("Add KD 2.750 more"). The selected card wears a green
/// frame and the pointer under it that ties it to the products below.
class CartDealCard extends StatelessWidget {
  const CartDealCard({
    super.key,
    required this.deal,
    required this.selected,
    required this.onTap,
  });

  final CartDealEntity deal;
  final bool selected;
  final VoidCallback onTap;

  static const double width = AppSize.s200;
  static const double pointerHeight = AppSize.s8;
  static const double _pointerWidth = AppSize.s16;
  static const double _frame = AppSize.s2;

  @override
  Widget build(BuildContext context) {
    final status = CartDealTexts.status(deal);
    final duration = MotionGuard.duration(context, AppMotion.fast);
    return Semantics(
      button: true,
      selected: selected,
      label: '${deal.name}, $status',
      excludeSemantics: true,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: PressScale(
              onTap: onTap,
              child: AnimatedContainer(
                duration: duration,
                curve: AppMotion.signature,
                width: width,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s10,
                  vertical: AppSpacing.s8,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.r3),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.white,
                    width: _frame,
                  ),
                  boxShadow: selected ? null : AppShadows.low,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CartDealIcon(type: deal.reward.type),
                        const SizedBox(width: AppSpacing.s6),
                        Flexible(
                          child: Text(
                            deal.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.itemTitleStrong.copyWith(
                              fontWeight: AppTextStyles.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: deal.applied
                            ? AppColors.brandDeep
                            : AppColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: _pointerWidth,
            height: pointerHeight,
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: duration,
              child: const CustomPaint(
                painter: CartDealPointerPainter(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
