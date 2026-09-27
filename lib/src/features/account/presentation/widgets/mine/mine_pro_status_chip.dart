import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/utils/formatters.dart';

/// Where the customer stands with Pro, on the Jm3eia Pro row: "Renews
/// 17 Oct" (violet) for a member, "Ends 17 Oct" (amber) once cancelled,
/// and a filled violet "Join" / "Rejoin" while Pro is on offer. Pops to
/// the new chip when the standing changes (a subscribe, a cancel).
class MineProStatusChip extends StatelessWidget {
  const MineProStatusChip({
    super.key,
    required this.membership,
    required this.offered,
  });

  final ProMembershipEntity membership;

  /// The store sells Pro to this customer (see `ProStatusState.canOffer`):
  /// the join chips show only then.
  final bool offered;

  @override
  Widget build(BuildContext context) {
    final date = Formatters.dayMonth(
      context.locale.languageCode,
      membership.periodEnd,
    );
    final (
      String? label,
      Color background,
      Color ink,
    ) = switch (membership.standing) {
      ProStanding.active => (
        date.isEmpty
            ? 'account.pro_active'.tr()
            : 'account.pro_renews'.tr(namedArgs: {'date': date}),
        AppColors.accentVioletLight,
        AppColors.accentViolet,
      ),
      ProStanding.ending => (
        date.isEmpty
            ? 'account.pro_active'.tr()
            : 'account.pro_ends'.tr(namedArgs: {'date': date}),
        AppColors.accent4Light,
        AppColors.accent4Foreground,
      ),
      ProStanding.lapsed => (
        offered ? 'account.pro_rejoin'.tr() : null,
        AppColors.accentViolet,
        AppColors.white,
      ),
      ProStanding.guest || ProStanding.prospect => (
        offered ? 'account.pro_join'.tr() : null,
        AppColors.accentViolet,
        AppColors.white,
      ),
    };
    return PopSwitcher(
      stateKey: label ?? '',
      child: label == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s2,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.captionMedium.copyWith(
                  fontWeight: AppTextStyles.bold,
                  color: ink,
                ),
              ),
            ),
    );
  }
}
