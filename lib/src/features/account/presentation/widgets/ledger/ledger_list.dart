import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/ledger.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import 'ledger_load_more_row.dart';

/// The loaded history as a pull-to-refresh list: [header] first, then the
/// entries (or [empty]), then the load-more sentinel while the server has
/// more.
class LedgerList<T extends LedgerEntry> extends StatelessWidget {
  const LedgerList({
    super.key,
    required this.ledger,
    required this.header,
    required this.entryBuilder,
    required this.empty,
  });

  final Ledger<T> ledger;
  final Widget header;
  final Widget Function(T entry) entryBuilder;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final entries = ledger.entries;
    final hasMore = ledger.hasMore && entries.isNotEmpty;
    // header · entries (or the empty view) · sentinel
    final count =
        1 + (entries.isEmpty ? 1 : entries.length) + (hasMore ? 1 : 0);
    return BrandedRefresh(
      onRefresh: () => context.read<LedgerCubit<T>>().refresh(),
      child: ContentClamp(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
          ),
          itemCount: count,
          itemBuilder: (_, index) {
            if (index == 0) return header;
            if (entries.isEmpty) return empty;
            final position = index - 1;
            if (position == entries.length) return LedgerLoadMoreRow<T>();
            final entry = entries[position];
            return Column(
              key: ValueKey<String>(entry.id),
              mainAxisSize: MainAxisSize.min,
              children: [
                entryBuilder(entry),
                const ThinDivider(indent: AppSpacing.s16),
              ],
            );
          },
        ),
      ),
    );
  }
}
