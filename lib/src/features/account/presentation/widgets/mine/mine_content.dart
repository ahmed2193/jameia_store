import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../cubit/account_cubit.dart';
import 'mine_delivery_code_cell.dart';
import 'mine_header_sliver.dart';
import 'mine_menu.dart';
import 'mine_stats_card.dart';

/// The Mine tab page: the collapsing profile header, then the quick stats,
/// the three menu cards and the delivery code, cascading in once (header first — it is the anchor, so it paints at once).
///
/// Waits for the overview (an in-memory read that resolves in a frame), so
/// the counts never flip from zero on open; a failed read still shows the
/// page, with zero counts and no code.
class MineContent extends StatelessWidget {
  const MineContent({super.key});

  static const int _menuEntrance = 1;
  static const int _codeEntrance = _menuEntrance + 3;

  @override
  Widget build(BuildContext context) {
    final resolved = context.select<AccountCubit, bool>(
      (account) => account.state.isResolved,
    );
    if (!resolved) return const SizedBox.shrink();
    return const EntranceCascade(
      child: CustomScrollView(
        slivers: [
          MineHeaderSliver(),
          SliverToBoxAdapter(
            child: ContentClamp(
              child: Column(
                children: [
                  SizedBox(height: AppSpacing.s16),
                  EntranceCascadeItem(index: 0, child: MineStatsCard()),
                  SizedBox(height: AppSpacing.s24),
                  MineMenu(firstEntranceIndex: _menuEntrance),
                  SizedBox(height: AppSpacing.s20),
                  EntranceCascadeItem(
                    index: _codeEntrance,
                    child: MineDeliveryCodeCell(),
                  ),
                  SizedBox(height: AppSpacing.s32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
