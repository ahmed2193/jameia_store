import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_close_button.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_text_link.dart';
import '../../cubit/tracking_alerts_cubit.dart';

/// A slim ask at the top of the panel while the phone's notification shade
/// is closed to the app: follow the rider from the lock screen. "Turn on"
/// asks the phone — only on that tap, never by itself — and the cross puts
/// the ask away for this map.
class LiveMapAlertsPrompt extends StatelessWidget {
  const LiveMapAlertsPrompt({super.key});

  static const double _disc = AppSize.s32;
  static const double _glyph = AppSize.s18;

  @override
  Widget build(BuildContext context) {
    final visible = context.select<TrackingAlertsCubit, bool>(
      (cubit) => cubit.state.showPrompt,
    );
    final cubit = context.read<TrackingAlertsCubit>();
    return CollapseReveal(
      visible: visible,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s12),
        child: Row(
          children: [
            const ExcludeSemantics(
              child: SizedBox.square(
                dimension: _disc,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.brandLightBg,
                    shape: BoxShape.circle,
                  ),
                  child: HeroIcon(
                    HeroIcons.bell,
                    size: _glyph,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                'orders.live_alerts_prompt'.tr(),
                style: AppTextStyles.bodyMedium,
              ),
            ),
            HeroTextLink(
              label: 'orders.live_alerts_turn_on'.tr(),
              onTap: cubit.allow,
              color: AppColors.primaryDark,
              navigates: false,
            ),
            HeroCloseButton(onPressed: cubit.dismissPrompt),
          ],
        ),
      ),
    );
  }
}
