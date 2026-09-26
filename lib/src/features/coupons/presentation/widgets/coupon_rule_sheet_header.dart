import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'coupon_stub.dart';

/// Top row of the coupon detail sheet: the warm ticket disc (pops in), the
/// coupon [title] and the close button.
class CouponRuleSheetHeader extends StatelessWidget {
  const CouponRuleSheetHeader({super.key, required this.title});

  final String title;

  static const double _iconDisc = AppSize.s44;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PopScale.onMount(
          child: SizedBox.square(
            dimension: _iconDisc,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: CouponStub.gradient,
                ),
              ),
              child: Icon(
                Icons.confirmation_number_rounded,
                size: AppSize.s22,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ),
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close_rounded, size: AppSize.s22),
          color: AppColors.tertiaryText,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
