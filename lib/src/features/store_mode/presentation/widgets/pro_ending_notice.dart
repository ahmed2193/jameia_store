import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';

/// Under a cancelled member's card: the membership will not renew and the
/// perks stay on until [periodEnd] — on a warm amber wash, popping in right
/// after the cancel. Nothing is taken away before that date.
class ProEndingNotice extends StatelessWidget {
  const ProEndingNotice({super.key, required this.periodEnd});

  final DateTime? periodEnd;

  static const double _icon = AppSize.s18;

  @override
  Widget build(BuildContext context) {
    final date = Formatters.date(context.locale.languageCode, periodEnd);
    if (date.isEmpty) return const SizedBox.shrink();
    return PopScale.onMount(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.accent4Light,
          borderRadius: BorderRadius.circular(AppRadius.r2),
          border: Border.all(color: AppColors.accent4Dark),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.event_available_rounded,
              size: _icon,
              color: AppColors.accent4Foreground,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                'pro.ending_notice'.tr(namedArgs: {'date': date}),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.accent4Foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
