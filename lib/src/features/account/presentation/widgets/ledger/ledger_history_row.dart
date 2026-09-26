import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'ledger_entry_tile.dart';
import 'ledger_fresh_flash.dart';
import 'ledger_row_entrance.dart';

/// One history row as the list lays it out: the tile, a hairline under it
/// (aligned with the text, not the icon) unless it closes its day, the
/// first-load entrance when it is one of the first rows, and the fresh-line
/// tint after a refresh brought it in.
class LedgerHistoryRow extends StatelessWidget {
  const LedgerHistoryRow({
    super.key,
    required this.child,
    required this.showDivider,
    this.entrance,
    this.flash,
  });

  final Widget child;
  final bool showDivider;
  final Animation<double>? entrance;

  /// Set only while this row is new from a refresh.
  final Animation<Color?>? flash;

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (showDivider)
          const Divider(
            height: AppSize.s1,
            thickness: AppSize.s1,
            color: AppColors.divider,
            indent: LedgerEntryTile.textInset,
            endIndent: AppSpacing.s16,
          ),
      ],
    );
    final tint = flash;
    return LedgerRowEntrance(
      animation: entrance,
      child: tint == null ? rows : LedgerFreshFlash(color: tint, child: rows),
    );
  }
}
