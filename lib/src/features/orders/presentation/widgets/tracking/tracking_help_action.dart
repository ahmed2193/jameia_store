import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// "Help" at the end of the order page's title bar (where delivery apps put
/// it): the help glyph and the word, on a soft green pill.
class TrackingHelpAction extends StatelessWidget {
  const TrackingHelpAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.s8),
      child: Center(
        child: Material(
          color: AppColors.brandWash,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HeroIcon(
                    HeroIcons.help,
                    size: AppSize.s18,
                    color: AppColors.brandDeep,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    'orders.help'.tr(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.brandDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
