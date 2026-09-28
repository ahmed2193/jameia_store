import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';

/// The two lines of the sign-in offer card: the welcome points a new account
/// gets ([bonus] > 0), or — when the store gives none, or has not answered
/// yet — what an account keeps for the customer.
class LoginOfferWords extends StatelessWidget {
  const LoginOfferWords({super.key, required this.bonus});

  final int bonus;

  @override
  Widget build(BuildContext context) {
    final hasBonus = bonus > 0;
    final title = hasBonus
        ? 'auth.offer_bonus_title'.tr(
            namedArgs: {'points': Formatters.isolate('$bonus')},
          )
        : 'auth.offer_title'.tr();
    final subtitle = hasBonus
        ? 'auth.offer_new_customers'.tr()
        : 'auth.offer_subtitle'.tr();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          subtitle,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
        ),
      ],
    );
  }
}
