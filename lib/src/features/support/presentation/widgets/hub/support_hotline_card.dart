import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/press_row.dart';
import 'support_section_card.dart';

/// The hotline row. Hero's `hotlinePhone` calls through `callPhone`; the
/// offline clone has no dialer bridge, so a snack bar stands in.
class SupportHotlineCard extends StatelessWidget {
  const SupportHotlineCard({super.key});

  static const String _hotline = '+965 2222 0000';

  @override
  Widget build(BuildContext context) {
    return SupportSectionCard(
      child: PressRow(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => showHeroSnackBar(
          context,
          'support.calling_hotline'.tr(namedArgs: {'number': _hotline}),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s14,
          ),
          child: Row(
            children: [
              const HeroIcon(
                HeroIcons.phone,
                size: AppSize.s20,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'support.call_hotline'.tr(),
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      _hotline,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.tertiaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const HeroIcon(
                HeroIcons.chevronEnd,
                size: AppSize.s16,
                color: AppColors.disabledText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
