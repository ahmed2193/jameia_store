import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import 'mine_stat_tile.dart';
import 'mine_tone.dart';

/// The loyalty points stat. Shows the balance as is on open; when points
/// land while the tab is open it counts from the last shown value to the
/// new one. Rebuilds only when the points change.
class MinePointsStat extends StatelessWidget {
  const MinePointsStat({super.key});

  @override
  Widget build(BuildContext context) {
    final points = context.select<AuthSessionCubit, int>(
      (cubit) =>
          cubit.state.isSignedIn ? cubit.state.customer?.loyaltyPoints ?? 0 : 0,
    );
    return MineStatTile(
      icon: Icons.stars_rounded,
      tone: MineTone.amber,
      label: 'account.points'.tr(),
      onTap: () => context.push(Routes.loyalty),
      value: RepaintBoundary(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CountUpText(
            value: points.toDouble(),
            maxLines: 1,
            format: (value) => '${value.round()}',
            style: MineStatTile.valueStyle,
          ),
        ),
      ),
    );
  }
}
