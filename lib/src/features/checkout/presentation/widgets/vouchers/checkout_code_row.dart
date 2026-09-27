import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../checkout/checkout_sheet_frame.dart';
import 'checkout_coupon_sheet.dart';

/// "Enter coupon code": a white 64 dp card with the tag glyph. A tap opens
/// the code sheet; once a code lands on the cart the sheet closes and this
/// page goes back to checkout, where the saving plays.
class CheckoutCodeRow extends StatelessWidget {
  const CheckoutCodeRow({super.key});

  static const double height = AppSize.s64;
  static const double _iconSize = AppSize.s22;
  static const double _iconGap = AppSpacing.s10;
  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.media),
  );

  Future<void> _open(BuildContext context) async {
    final applied = await CheckoutSheetFrame.show<bool>(
      context,
      builder: (_) => const CheckoutCouponSheet(),
    );
    if (applied == true && context.mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
      child: Material(
        color: AppColors.white,
        borderRadius: _radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    HeroAssets.checkoutCodeTag,
                    width: _iconSize,
                    height: _iconSize,
                    excludeFromSemantics: true,
                  ),
                  const SizedBox(width: _iconGap),
                  Expanded(
                    child: Text(
                      'checkout.code_row'.tr(),
                      style: AppTextStyles.itemTitle.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppSize.s20,
                    color: AppColors.tertiaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
