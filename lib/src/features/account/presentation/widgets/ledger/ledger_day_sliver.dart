import 'package:flutter/material.dart';

import '../../../domain/entities/ledger_entry.dart';
import 'ledger_day_header.dart';
import 'ledger_history_row.dart';
import 'ledger_row_entrance.dart';

/// One day of the history: its title pinned while the day scrolls by (the
/// next day's title pushes it out), then its rows. Entrance slots run in
/// reading order from [firstSlot] (the title) on.
class LedgerDaySliver<T extends LedgerEntry> extends StatelessWidget {
  const LedgerDaySliver({
    super.key,
    required this.title,
    required this.entries,
    required this.entryBuilder,
    required this.firstSlot,
    required this.entranceOf,
    required this.freshIds,
    required this.flash,
  });

  final String title;
  final List<T> entries;
  final Widget Function(T entry) entryBuilder;
  final int firstSlot;

  /// The first-load entrance of a slot; `null` past the staggered ones.
  final Animation<double>? Function(int slot) entranceOf;

  /// Lines a refresh just brought in (tinted by [flash]).
  final Set<String> freshIds;
  final Animation<Color?> flash;

  @override
  Widget build(BuildContext context) {
    final last = entries.length - 1;
    return SliverMainAxisGroup(
      slivers: [
        PinnedHeaderSliver(
          child: LedgerRowEntrance(
            animation: entranceOf(firstSlot),
            child: LedgerDayHeader(title),
          ),
        ),
        SliverList.builder(
          itemCount: entries.length,
          itemBuilder: (_, index) {
            final entry = entries[index];
            return LedgerHistoryRow(
              key: ValueKey<String>(entry.id),
              showDivider: index < last,
              entrance: entranceOf(firstSlot + 1 + index),
              flash: freshIds.contains(entry.id) ? flash : null,
              child: entryBuilder(entry),
            );
          },
        ),
      ],
    );
  }
}
