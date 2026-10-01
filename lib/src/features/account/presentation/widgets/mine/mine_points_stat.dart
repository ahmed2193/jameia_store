import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/rolling_number.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import 'mine_stat_tile.dart';
import 'mine_tone.dart';

/// The loyalty points stat. Shows the balance as is on open; when points
/// land while the tab is open only the digits that changed roll, the way
/// the wallet beside it moves ([RollingNumber]). Rebuilds only when the
/// points change.
class MinePointsStat extends StatelessWidget {
  const MinePointsStat({super.key});

  @override
  Widget build(BuildContext context) {
    final points = context.select<AuthSessionCubit, int>(
      (cubit) =>
          cubit.state.isSignedIn ? cubit.state.customer?.loyaltyPoints ?? 0 : 0,
    );
    return MineStatTile(
      icon: HeroIcons.points,
      tone: MineTone.amber,
      label: 'account.points'.tr(),
      onTap: () => context.push(Routes.loyalty),
      value: RollingNumber(value: points, style: MineStatTile.valueStyle),
    );
  }
}
