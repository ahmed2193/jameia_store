import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/coupon_entity.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/motion/entrance_cascade_item.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/hero_sheet_header.dart';
import 'coupon_rule_row.dart';
import 'coupon_ticket_disc.dart';

/// Detail sheet of a coupon (opened by tapping its ticket): the title, the
/// discount, minimum spend and validity on a cream card, the terms, and
/// "Got it". Closed by the X or the button.
class CouponRuleSheet extends StatelessWidget {
  const CouponRuleSheet({super.key, required this.coupon});

  final CouponEntity coupon;

  /// Opens the sheet for [coupon] over the current screen.
  static Future<void> show(BuildContext context, CouponEntity coupon) =>
      showHeroBottomSheet<void>(
        context,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        builder: (_) => CouponRuleSheet(coupon: coupon),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroSheetHeader(
            title: coupon.titleFor(context.locale.languageCode),
            leading: const CouponTicketDisc(),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntranceCascadeItem.single(
                    index: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.accent3Light,
                        borderRadius: BorderRadius.circular(AppRadius.r3),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s8,
                        ),
                        child: Column(
                          children: [
                            CouponRuleRow(
                              label: 'coupons.discount'.tr(),
                              value: 'coupons.amount_off'.tr(
                                namedArgs: {
                                  'value': Formatters.price(coupon.amount),
                                },
                              ),
                            ),
                            CouponRuleRow(
                              label: 'coupons.min_spend'.tr(),
                              value: Formatters.price(coupon.minSpend),
                            ),
                            CouponRuleRow(
                              label: 'coupons.valid_until'.tr(),
                              value: coupon.expiry,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  EntranceCascadeItem.single(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'coupons.terms'.tr(),
                          style: AppTextStyles.headingSmall.copyWith(
                            fontWeight: AppTextStyles.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          'coupons.terms_body'.tr(),
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.secondaryText,
                            height: AppSize.lh1_5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  EntranceCascadeItem.single(
                    index: 3,
                    child: AppButton(
                      label: 'coupons.got_it'.tr(),
                      onPressed: () => context.pop(),
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
