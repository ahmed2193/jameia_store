import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import 'checkout_bar_fact_text.dart';

/// The line under the bar's total while the app is offline, in place of the
/// rotating facts: placing the order needs the connection (the button still
/// checks for itself when tapped). Calm grey, the same size as the facts.
class CheckoutOfflineLine extends StatelessWidget {
  const CheckoutOfflineLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.wifi_off_rounded,
          size: CheckoutBarFactText.iconSize,
          color: AppColors.secondaryText,
        ),
        const SizedBox(width: AppSpacing.s4),
        Flexible(
          child: Text(
            'connectivity.offline_title'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}
