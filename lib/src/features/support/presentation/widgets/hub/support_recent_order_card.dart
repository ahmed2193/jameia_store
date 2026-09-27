import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entities/support_order.dart';
import 'support_section_card.dart';

/// "Get help with this order": the newest order's shop, date, total and lines,
/// with a button into the help topics.
class SupportRecentOrderCard extends StatelessWidget {
  const SupportRecentOrderCard({super.key, required this.order});

  final SupportOrder order;

  static const double _buttonHeight = 42;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final itemNames = order.lines
        .map((line) => '${line.nameFor(languageCode)} ×${line.qty}')
        .join(', ');
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
      child: SupportSectionCard(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HeroImage.circle(url: order.shopLogo, size: AppSize.s40),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        order.shopNameFor(languageCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingMedium.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        order.dateFor(languageCode),
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.price(order.total),
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
              ],
            ),
            if (itemNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                itemNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            AppButton(
              label: 'support.get_help_with_order'.tr(),
              height: _buttonHeight,
              onPressed: () =>
                  context.push(Routes.customerServiceQuestion, extra: order.id),
            ),
          ],
        ),
      ),
    );
  }
}
