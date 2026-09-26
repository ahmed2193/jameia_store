import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/coupon_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_button.dart';

/// Sticky bar of the checkout picker; slides up from the bottom once. It says
/// what the picked coupon saves (flipping when the pick changes) and
/// "Confirm" returns the pick.
///
/// Not wrapped in `ContentClamp`: its `Align` would expand to the loose
/// height a `bottomNavigationBar` gets and balloon the bar to full screen.
class OrderCouponsConfirmBar extends StatelessWidget {
  const OrderCouponsConfirmBar({
    super.key,
    required this.selected,
    required this.onConfirm,
  });

  final CouponEntity? selected;
  final VoidCallback onConfirm;

  static const Offset _slideUp = Offset(0, 1);
  static const BorderRadius _radius = BorderRadius.vertical(
    top: Radius.circular(AppRadius.r2),
  );

  /// Cast upward, onto the list scrolling under the bar.
  static const List<BoxShadow> _shadow = [
    BoxShadow(
      color: AppColors.shadowInk10,
      offset: Offset(0, -AppSpacing.s4),
      blurRadius: AppSpacing.s20,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pick = selected;
    return StaggerEntrance(
      index: 0,
      beginOffset: _slideUp,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: _radius,
          boxShadow: _shadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s16,
              AppSpacing.s12,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FlipValue(
                  flipKey: pick?.id ?? '',
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    pick == null
                        ? 'coupons.no_coupon_selected'.tr()
                        : 'coupons.you_save'.tr(
                            namedArgs: {
                              'amount': Formatters.price(pick.amount),
                            },
                          ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: AppTextStyles.bold,
                      color: pick == null
                          ? AppColors.secondaryText
                          : AppColors.accent3Dark,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s10),
                AppButton(
                  label: 'coupons.confirm'.tr(),
                  radius: AppRadius.pill,
                  onPressed: onConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
