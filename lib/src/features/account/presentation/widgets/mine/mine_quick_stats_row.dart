import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/utils/formatters.dart';
import 'mine_stat_cell.dart';
import 'mine_stat_divider.dart';

/// Coupons · wallet · favourites (bundle `j6507b`): white card, radius 12dp,
/// 12dp side margin; each stat opens its screen.
class MineQuickStatsRow extends StatelessWidget {
  const MineQuickStatsRow({
    super.key,
    required this.coupons,
    required this.favourites,
    required this.walletKd,
  });

  final int coupons;
  final int favourites;
  final double walletKd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s16,
          horizontal: AppSpacing.s4,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: MineStatCell(
                  value: '$coupons',
                  label: 'account.coupons'.tr(),
                  onTap: () => context.push(Routes.myCoupons),
                ),
              ),
              const MineStatDivider(),
              Expanded(
                child: MineStatCell(
                  value: Formatters.price(walletKd),
                  label: 'account.wallet'.tr(),
                  onTap: () => context.push(Routes.wallet),
                ),
              ),
              const MineStatDivider(),
              Expanded(
                child: MineStatCell(
                  value: '$favourites',
                  label: 'account.favourites'.tr(),
                  onTap: () => context.push(Routes.shopFavorites),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
