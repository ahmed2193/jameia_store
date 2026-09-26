import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/motion/motion_widgets.dart';
import '../../cubit/account_cubit.dart';
import 'mine_stat_tile.dart';
import 'mine_tone.dart';

/// A count stat from the Mine overview (coupons, favourites): the number
/// flips when it changes and the tile opens [route]. Rebuilds only when its
/// own count changes ([count] picks it from the state).
class MineCountStat extends StatelessWidget {
  const MineCountStat({
    super.key,
    required this.count,
    required this.icon,
    required this.tone,
    required this.label,
    required this.route,
  });

  final int Function(AccountState state) count;
  final IconData icon;
  final MineTone tone;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final value = context.select<AccountCubit, int>(
      (cubit) => count(cubit.state),
    );
    return MineStatTile(
      icon: icon,
      tone: tone,
      label: label,
      onTap: () => context.push(route),
      value: RepaintBoundary(
        child: FlipValue(
          flipKey: value,
          alignment: AlignmentDirectional.center,
          child: Text('$value', maxLines: 1, style: MineStatTile.valueStyle),
        ),
      ),
    );
  }
}
