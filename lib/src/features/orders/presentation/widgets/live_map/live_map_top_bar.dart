import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_map_button.dart';
import 'live_map_live_dot.dart';

/// Floats over the top of the live map: back to the order (the same round
/// map button as the address picker's), and a white pill saying the map is
/// live.
class LiveMapTopBar extends StatelessWidget {
  const LiveMapTopBar({super.key});

  /// Its height under the status bar: the map keeps this much room.
  static const double height = AppSize.s64;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: Row(
            children: [
              HeroMapButton(
                icon: HeroIcons.back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: AppSpacing.s12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.medium,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.s8,
                    AppSpacing.s6,
                    AppSpacing.s14,
                    AppSpacing.s6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LiveMapLiveDot(),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        'orders.live_title'.tr(),
                        style: AppTextStyles.label,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
