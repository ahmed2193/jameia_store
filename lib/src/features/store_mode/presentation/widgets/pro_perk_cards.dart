import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../domain/entities/pro_membership.dart';
import '../cubit/pro_membership_cubit.dart';
import '../cubit/pro_membership_state.dart';
import 'pro_perk_card.dart';

/// The programme's perks as cards, only those the store switched on: the
/// points boost (with a link to the rewards), the order discount, and the
/// member prices every plan includes. For a member they are "Your perks",
/// each marked "On". The cards rise into view one after another the first
/// time they scroll on screen.
class ProPerkCards extends StatelessWidget {
  const ProPerkCards({super.key});

  static const Duration _stagger = Duration(milliseconds: 60);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ProMembershipCubit,
      ProMembershipState,
      ({ProPerks perks, bool isMember})
    >(
      selector: (state) =>
          (perks: state.program.perks, isMember: state.isMember),
      builder: (context, selection) {
        final perks = selection.perks;
        final isMember = selection.isMember;
        final multiplier = {'multiplier': '${perks.pointsMultiplier}'};
        final percent = {'percent': '${perks.discountPercent}'};
        final cards = [
          if (perks.hasPointsBoost)
            ProPerkCard(
              color: AppColors.accentSkyLight,
              icon: Icons.stars_rounded,
              title: 'pro.perk_points_title'.tr(namedArgs: multiplier),
              body: 'pro.perk_points_body'.tr(namedArgs: multiplier),
              ctaLabel: 'pro.perk_points_cta'.tr(),
              onCta: () => context.push(Routes.loyaltyRewards),
              active: isMember,
            ),
          if (perks.hasDiscount)
            ProPerkCard(
              color: AppColors.accent3Light,
              icon: Icons.percent_rounded,
              title: 'pro.perk_discount_title'.tr(namedArgs: percent),
              body: 'pro.perk_discount_body'.tr(namedArgs: percent),
              active: isMember,
            ),
          ProPerkCard(
            color: AppColors.brandLightBg,
            icon: Icons.sell_rounded,
            title: 'pro.perk_prices_title'.tr(),
            body: 'pro.perk_prices_body'.tr(),
            active: isMember,
          ),
        ];
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s16,
            AppSpacing.s24,
            AppSpacing.s16,
            0,
          ),
          child: Column(
            spacing: AppSpacing.s12,
            children: [
              if (isMember)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Semantics(
                    header: true,
                    child: Text(
                      'pro.your_perks'.tr(),
                      style: AppTextStyles.headingLarge.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < cards.length; i++)
                ScrollReveal(delay: _stagger * i, child: cards[i]),
            ],
          ),
        );
      },
    );
  }
}
