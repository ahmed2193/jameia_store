import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// The rail's heading: "Deals you might have missed" (20 sp medium) and the
/// honest line under it — "On sale now and in stock" — in the 12 dp gutter,
/// 24 dp under the band's top and 16 dp above the cards.
class CheckoutRailHeader extends StatelessWidget {
  const CheckoutRailHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s24,
        AppSpacing.s12,
        AppSpacing.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(
              'checkout.rail_title'.tr(),
              style: AppTextStyles.sectionTitle.copyWith(
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'checkout.rail_subtitle'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
