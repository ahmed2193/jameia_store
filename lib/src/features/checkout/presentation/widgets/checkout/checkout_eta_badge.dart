import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/responsive/app_size.dart';

/// The express mark of the "Expected" row, shown only while express is on
/// the order ([express]): the green ⚡ plate when express really beats the
/// standard estimate ([bolt]), otherwise a plain "Express" tag — never a
/// "faster" claim the numbers do not back. It bumps once when express comes
/// or goes (no haptic: the sheet row already buzzed).
class CheckoutEtaBadge extends StatelessWidget {
  const CheckoutEtaBadge({
    super.key,
    required this.express,
    required this.bolt,
  });

  /// The ⚡ plate (the Keeta badge, 19 × 13 dp).
  static const double boltWidth = AppSize.s19;
  static const double boltHeight = AppSize.s13;

  static const BorderRadius _tagRadius = BorderRadius.all(
    Radius.circular(AppSize.r3),
  );

  final bool express;
  final bool bolt;

  @override
  Widget build(BuildContext context) {
    return ChangeBump(
      value: express,
      child: !express
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.s6),
              child: bolt
                  ? SvgPicture.asset(
                      JameiaAssets.checkoutExpressBolt,
                      width: boltWidth,
                      height: boltHeight,
                      semanticsLabel: 'checkout.express_tag'.tr(),
                    )
                  : DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.brandLightBg,
                        borderRadius: _tagRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s4,
                        ),
                        child: Text(
                          'checkout.express_tag'.tr(),
                          maxLines: 1,
                          style: AppTextStyles.tag.copyWith(
                            color: AppColors.brandDeep,
                          ),
                        ),
                      ),
                    ),
            ),
    );
  }
}
