import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/screen_stale_notice.dart';
import '../../../domain/entities/ledger.dart';
import '../../../domain/entities/ledger_change.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import 'ledger_dates.dart';
import 'ledger_day_sliver.dart';
import 'ledger_load_more_row.dart';

/// The loaded history as a pull-to-refresh scroll: the "Updated … ago" note
/// over a saved or failed history, [header], then the entries grouped by
/// day under pinned day titles (or [empty]), then the load-more sentinel
/// while the server has more.
///
/// Motion: the first rows cascade in once when the list first appears
/// ([EntranceCascade]; never on a refresh, a later page or a row scrolled
/// back into view), and the lines a pull-to-refresh brings in flash a soft
/// green once (one controller owned here).
class LedgerList<T extends LedgerEntry> extends StatefulWidget {
  const LedgerList({
    super.key,
    required this.ledger,
    required this.header,
    required this.entryBuilder,
    required this.entryDate,
    required this.empty,
    required this.todayLabel,
    required this.yesterdayLabel,
  });

  final Ledger<T> ledger;
  final Widget header;
  final Widget Function(T entry) entryBuilder;

  /// When a line was booked — what the days group on.
  final DateTime Function(T entry) entryDate;
  final Widget empty;
  final String todayLabel;
  final String yesterdayLabel;

  @override
  State<LedgerList<T>> createState() => _LedgerListState<T>();
}

class _LedgerListState<T extends LedgerEntry> extends State<LedgerList<T>>
    with SingleTickerProviderStateMixin {
  static final Duration _flashLength = AppMotion.slow * 2.5; // 1s
  static final Color _flashClear = AppColors.brandLightBg.withValues(alpha: 0);

  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: _flashLength,
  );
  late final Animation<Color?> _flashColor = ColorTween(
    begin: AppColors.brandLightBg,
    end: _flashClear,
  ).animate(CurvedAnimation(parent: _flash, curve: AppMotion.exit));

  Set<String> _fresh = const <String>{};

  @override
  void initState() {
    super.initState();
    _flash.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _fresh = const <String>{});
      }
    });
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  void _onChange(LedgerChange change) {
    if (change.newEntryIds.isEmpty) return;
    setState(() => _fresh = change.newEntryIds);
    // Reduced motion: a short colour change instead of the slow fade.
    _flash.duration = MotionGuard.reduced(context)
        ? AppMotion.fast
        : _flashLength;
    _flash.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger;
    final languageCode = context.locale.languageCode;
    final now = DateTime.now();
    final days = ledger.daysBy(widget.entryDate);
    final firstSlots = <int>[];
    var slot = 0;
    for (final day in days) {
      firstSlots.add(slot);
      slot += 1 + day.entries.length;
    }
    return BlocListener<LedgerCubit<T>, LedgerState<T>>(
      listenWhen: (previous, current) =>
          previous.changeSerial != current.changeSerial,
      listener: (_, state) => _onChange(state.change),
      child: BrandedRefresh(
        onRefresh: () => context.read<LedgerCubit<T>>().refresh(),
        child: ContentClamp(
          child: EntranceCascade(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: ScreenStaleNotice<LedgerCubit<T>, LedgerState<T>>(),
                ),
                SliverToBoxAdapter(child: widget.header),
                if (days.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: widget.empty,
                  ),
                for (var index = 0; index < days.length; index++)
                  LedgerDaySliver<T>(
                    key: ValueKey<DateTime>(days[index].date),
                    title: LedgerDates.dayTitle(
                      languageCode: languageCode,
                      day: days[index],
                      now: now,
                      today: widget.todayLabel,
                      yesterday: widget.yesterdayLabel,
                    ),
                    entries: days[index].entries,
                    entryBuilder: widget.entryBuilder,
                    firstSlot: firstSlots[index],
                    freshIds: _fresh,
                    flash: _flashColor,
                  ),
                // A lazy sliver: the sentinel is built — and asks for the
                // next page — only once it scrolls into reach.
                if (ledger.hasMore && !ledger.isEmpty)
                  SliverList.list(children: [LedgerLoadMoreRow<T>()]),
                SliverPadding(
                  padding: EdgeInsetsDirectional.only(
                    bottom:
                        MediaQuery.paddingOf(context).bottom + AppSpacing.s16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
