import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_text_link.dart';

/// The line over the map picker's Confirm, Glovo style — a flat white card:
/// how to place the pin, or, with the pin outside Kuwait, why Confirm is
/// grey and a way back in ([onChooseArea]: the areas Hero delivers to). The
/// two cross-fade.
class PinHintCard extends StatelessWidget {
  const PinHintCard({
    super.key,
    required this.outside,
    required this.onChooseArea,
  });

  final bool outside;
  final VoidCallback onChooseArea;

  static const double _minHeight = AppSize.s48;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.subheadingLarge.copyWith(
      color: AppColors.primaryText,
    );
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s4,
        outside ? AppSpacing.s8 : AppSpacing.s16,
        AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r6),
        boxShadow: AppShadows.medium,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FadeThroughSwitcher(
        stateKey: outside,
        crossFade: true,
        alignment: AlignmentDirectional.centerStart,
        child: outside
            ? Row(
                children: [
                  const HeroIcon(HeroIcons.warning, size: AppSize.s20),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: Text('addr.map.outside_hint'.tr(), style: style),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  HeroTextLink(
                    label: 'addr.map.choose_area'.tr(),
                    color: AppColors.brandDeep,
                    onTap: onChooseArea,
                  ),
                ],
              )
            : Text('addr.map.move_hint'.tr(), style: style),
      ),
    );
  }
}
