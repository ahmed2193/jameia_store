import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../cubit/pro_membership_cubit.dart';
import 'pro_brand_rows.dart';
import 'pro_underlined_link.dart';
import 'pro_wave_clipper.dart';

/// Lavender band selling free delivery (only when the programme includes it):
/// the headline, the brands it covers drifting by, and a link to all brands.
/// Rises into view the first time it scrolls on screen.
class ProDeliverySection extends StatelessWidget {
  const ProDeliverySection({super.key});

  static const EdgeInsetsDirectional _gutter = EdgeInsetsDirectional.symmetric(
    horizontal: AppSpacing.s16,
  );

  @override
  Widget build(BuildContext context) {
    final freeDelivery = context.select<ProMembershipCubit, bool>(
      (cubit) => cubit.state.program.perks.freeDelivery,
    );
    if (!freeDelivery) return const SizedBox.shrink();
    final headline = AppTextStyles.displayLarge.copyWith(
      fontSize: AppSize.font40,
      height: AppSize.lh1_1,
      fontWeight: AppTextStyles.bold,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.s24),
      child: ScrollReveal(
        child: ClipPath(
          clipper: const ProWaveClipper(),
          child: ColoredBox(
            color: AppColors.accentVioletLight,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpacing.s40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The headline reads as its own group, apart from the
                  // brand tiles and the link.
                  Semantics(
                    container: true,
                    child: Padding(
                      padding: _gutter,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'pro.delivery_title_line1'.tr(),
                            style: headline.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'pro.delivery_title_line2'.tr(),
                            style: headline.copyWith(
                              color: AppColors.accentViolet,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            'pro.delivery_body'.tr(),
                            style: AppTextStyles.subheadingLarge.copyWith(
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const ProBrandRows(),
                  const SizedBox(height: AppSpacing.s8),
                  Padding(
                    padding: _gutter,
                    child: ProUnderlinedLink(
                      label: 'pro.brands_view_all'.tr(),
                      onTap: () => context.push(Routes.brands),
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
