import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/press_row.dart';
import '../../../domain/entities/faq_item.dart';

/// One hub topic: opens the help topics with this question open.
class SupportFaqRow extends StatelessWidget {
  const SupportFaqRow({super.key, required this.faq});

  final FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return PressRow(
      onTap: () =>
          context.push(Routes.customerServiceQuestion, extra: faq.questionKey),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            const Icon(
              HeroIcons.help,
              size: AppSize.s18,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                faq.questionKey.tr(),
                style: AppTextStyles.headingSmall,
              ),
            ),
            const Icon(
              HeroIcons.arrowRight,
              size: AppSize.s16,
              color: AppColors.disabledText,
            ),
          ],
        ),
      ),
    );
  }
}
