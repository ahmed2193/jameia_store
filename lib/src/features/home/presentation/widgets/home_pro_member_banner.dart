import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/hero_svg_glyph.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_layout.dart';
import 'home_pro_perk_chip.dart';

/// A Pro member's card at the end of the home feed, in place of the offer:
/// "You're a Pro member" on the Pro gradient, the perks already on (each
/// with a check) and when the membership renews. Once cancelled
/// ([ProStanding.ending]) it says when the perks end and that nothing
/// renews. Opens the member hub; sells nothing.
class HomeProMemberBanner extends StatelessWidget {
  const HomeProMemberBanner({
    super.key,
    required this.pro,
    required this.membership,
    required this.onTap,
  });

  final HomeProInfo pro;
  final ProMembershipEntity membership;
  final VoidCallback onTap;

  static const LinearGradient _gradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: AppColors.proGradient,
  );

  @override
  Widget build(BuildContext context) {
    final date = Formatters.date(
      context.locale.languageCode,
      membership.periodEnd,
    );
    final ending = membership.standing == ProStanding.ending;
    final title = ending && date.isNotEmpty
        ? 'home.pro_ending_title'.tr(namedArgs: {'date': date})
        : 'home.pro_member_title'.tr();
    final subtitle = ending
        ? 'home.pro_ending_subtitle'.tr()
        : 'home.pro_member_subtitle'.tr();
    return Semantics(
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s14),
          decoration: BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.circular(HomeLayout.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HeroSvgGlyph.art(
                    HeroAssets.proCrown,
                    size: AppSize.s20,
                  ),
                  const SizedBox(width: AppSpacing.s6),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'home.pro_manage_cta'.tr(),
                    maxLines: 1,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: AppSize.s20,
                    color: AppColors.white,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                subtitle,
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.subtitleOverlay,
                ),
              ),
              const SizedBox(height: AppSpacing.s10),
              Wrap(
                spacing: AppSpacing.s6,
                runSpacing: AppSpacing.s6,
                children: [
                  if (pro.freeDelivery)
                    HomeProPerkChip(
                      label: 'home.pro_free_delivery'.tr(),
                      active: true,
                    ),
                  if (pro.hasPointsBoost)
                    HomeProPerkChip(
                      label: 'home.pro_points'.tr(
                        namedArgs: {'multiplier': '${pro.pointsMultiplier}'},
                      ),
                      active: true,
                    ),
                  if (pro.hasDiscount)
                    HomeProPerkChip(
                      label: 'home.pro_discount'.tr(
                        namedArgs: {'percent': '${pro.discountPercent}'},
                      ),
                      active: true,
                    ),
                ],
              ),
              if (!ending && date.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s10),
                Text(
                  'home.pro_member_renews'.tr(namedArgs: {'date': date}),
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.subtitleOverlay,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
