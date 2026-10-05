import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import 'home_free_delivery_chip.dart';

/// The first-order bar's line: "[Free delivery] on your first order" — the
/// offer picked out in its chip, the rest in bold white, wrapping onto a
/// second line in a long language rather than shrinking.
class HomeFirstOrderHeadline extends StatelessWidget {
  const HomeFirstOrderHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: HomeFreeDeliveryChip(label: 'home.first_order_free'.tr()),
          ),
          const WidgetSpan(child: SizedBox(width: AppSpacing.s6)),
          TextSpan(text: 'home.first_order_rest'.tr()),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.headingSmall.copyWith(
        color: AppColors.white,
        fontWeight: AppTextStyles.bold,
      ),
    );
  }
}
