import 'package:equatable/equatable.dart';

/// How a [LedgerDay] relates to "now": the history titles its groups
/// "Today", "Yesterday", a date without the year this year, a full date
/// before that.
enum LedgerDayKind { today, yesterday, thisYear, older }

/// The lines of one local calendar day of a ledger, newest first
/// (`Ledger.daysBy`).
class LedgerDay<T> extends Equatable {
  const LedgerDay({required this.date, required this.entries});

  /// Local midnight of the day.
  final DateTime date;
  final List<T> entries;

  /// Where this day sits relative to [now] (local time).
  LedgerDayKind kindOn(DateTime now) {
    final today = dayOf(now);
    if (date == today) return LedgerDayKind.today;
    if (date == DateTime(today.year, today.month, today.day - 1)) {
      return LedgerDayKind.yesterday;
    }
    return date.year == today.year
        ? LedgerDayKind.thisYear
        : LedgerDayKind.older;
  }

  /// Local midnight of [at].
  static DateTime dayOf(DateTime at) {
    final local = at.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  @override
  List<Object?> get props => [date, entries];
}
