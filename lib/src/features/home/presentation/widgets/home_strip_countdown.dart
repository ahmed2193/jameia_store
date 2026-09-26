import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_countdown_text.dart';

/// "Ends in 02:13:44" under a campaign headline, when the backend set an end.
class HomeStripCountdown extends StatelessWidget {
  const HomeStripCountdown({
    super.key,
    required this.endsAt,
    required this.labelColor,
    required this.digitsColor,
  });

  final DateTime endsAt;
  final Color labelColor;
  final Color digitsColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'home.ends_in'.tr(),
          style: AppTextStyles.captionLarge.copyWith(color: labelColor),
        ),
        const SizedBox(width: AppSpacing.s4),
        HomeCountdownText(
          endsAt: endsAt,
          style: AppTextStyles.digits(AppSize.font13)
              .copyWith(color: digitsColor, fontWeight: AppTextStyles.bold),
        ),
      ],
    );
  }
}
