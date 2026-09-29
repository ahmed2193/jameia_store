import 'package:flutter/material.dart';

import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../domain/entities/ledger_entry.dart';
import 'ledger_day_header.dart';
import 'ledger_history_row.dart';

/// One day of the history: its title pinned while the day scrolls by (the
/// next day's title pushes it out), then its rows. Their places in the
/// list's entrance cascade run in reading order from [firstSlot] (the
/// title) on.
class LedgerDaySliver<T extends LedgerEntry> extends StatelessWidget {
  const LedgerDaySliver({
    super.key,
    required this.title,
    required this.entries,
    required this.entryBuilder,
    required this.firstSlot,
    required this.freshIds,
    required this.flash,
  });

  final String title;
  final List<T> entries;
  final Widget Function(T entry) entryBuilder;
  final int firstSlot;

  /// Lines a refresh just brought in (tinted by [flash]).
  final Set<String> freshIds;
  final Animation<Color?> flash;

  @override
  Widget build(BuildContext context) {
    final last = entries.length - 1;
    return SliverMainAxisGroup(
      slivers: [
        PinnedHeaderSliver(
          child: EntranceCascadeItem(
            index: firstSlot,
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
              entranceIndex: firstSlot + 1 + index,
              flash: freshIds.contains(entry.id) ? flash : null,
              child: entryBuilder(entry),
            );
          },
        ),
      ],
    );
  }
}
