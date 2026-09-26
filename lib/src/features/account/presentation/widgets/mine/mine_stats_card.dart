import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../cubit/account_cubit.dart';
import 'mine_count_stat.dart';
import 'mine_points_stat.dart';
import 'mine_stat_divider.dart';
import 'mine_tone.dart';
import 'mine_wallet_stat.dart';

/// Wallet · points · coupons · favourites on one white card. Each stat
/// selects only its own value, so a balance change never rebuilds the rest.
class MineStatsCard extends StatelessWidget {
  const MineStatsCard({super.key});

  static int _coupons(AccountState state) => state.couponCount;
  static int _favourites(AccountState state) => state.favouriteCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s16),
      padding: const EdgeInsetsDirectional.symmetric(
        vertical: AppSpacing.s12,
        horizontal: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
        boxShadow: AppShadows.low,
      ),
      child: Row(
        children: [
          const Expanded(child: MineWalletStat()),
          const MineStatDivider(),
          const Expanded(child: MinePointsStat()),
          const MineStatDivider(),
          Expanded(
            child: MineCountStat(
              count: _coupons,
              icon: Icons.confirmation_num_rounded,
              tone: MineTone.orange,
              label: 'account.coupons'.tr(),
              route: Routes.myCoupons,
            ),
          ),
          const MineStatDivider(),
          Expanded(
            child: MineCountStat(
              count: _favourites,
              icon: JameiaIcons.favorite,
              tone: MineTone.rose,
              label: 'account.favourites'.tr(),
              route: Routes.shopFavorites,
            ),
          ),
        ],
      ),
    );
  }
}
