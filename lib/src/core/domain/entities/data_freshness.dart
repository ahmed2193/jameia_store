import 'package:equatable/equatable.dart';

import 'data_snapshot.dart';

/// How fresh the data on a screen is — the part of every cached screen's
/// state behind the "Updated 12 minutes ago" note and the reconnect refresh.
class DataFreshness extends Equatable {
  const DataFreshness({
    this.fetchedAt,
    this.fromCache = false,
    this.refreshFailed = false,
  });

  /// From the snapshot the screen now shows.
  factory DataFreshness.of(DataSnapshot<Object?> snapshot) => DataFreshness(
    fetchedAt: snapshot.fetchedAt,
    fromCache: snapshot.isFromCache,
  );

  /// Nothing loaded yet.
  static const DataFreshness none = DataFreshness();

  /// When the server produced the data on screen; `null` before any.
  final DateTime? fetchedAt;

  /// The data on screen is the device copy.
  final bool fromCache;

  /// The last request for fresher data failed; the data stays on screen.
  final bool refreshFailed;

  /// The data on screen did not come from the server just now: a reconnect
  /// refreshes it.
  bool get isStale => fetchedAt != null && (fromCache || refreshFailed);

  /// The data on screen is kept, but asking for fresher data failed.
  DataFreshness failed() => fetchedAt == null
      ? this
      : DataFreshness(
          fetchedAt: fetchedAt,
          fromCache: fromCache,
          refreshFailed: true,
        );

  /// A screen built from two reads shown together (the Pro page's
  /// programme and subscription): stale when either is, dated by the older.
  /// A read that has not answered yet ([none]) does not count.
  DataFreshness alongside(DataFreshness other) {
    final mine = fetchedAt;
    final theirs = other.fetchedAt;
    if (mine == null) return other;
    if (theirs == null) return this;
    return DataFreshness(
      fetchedAt: mine.isBefore(theirs) ? mine : theirs,
      fromCache: fromCache || other.fromCache,
      refreshFailed: refreshFailed || other.refreshFailed,
    );
  }

  /// The note shows over stale data while offline, or once its refresh
  /// failed — never while a refresh is still on its way (no flash of "5
  /// minutes ago" on every open).
  bool noticeVisible({required bool offline}) =>
      isStale && (offline || refreshFailed);

  /// Live data that is not live right now: offline (nothing refreshes it)
  /// or its last check failed — shown as "last known", never as the live
  /// state.
  bool isLastKnown({required bool offline}) =>
      fetchedAt != null && (offline || refreshFailed);

  @override
  List<Object?> get props => [fetchedAt, fromCache, refreshFailed];
}
