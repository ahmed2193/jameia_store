import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/ledger_day.dart';

/// Date text of the history: the time on a row (its day is the group
/// title) and the group titles themselves. Formats are cached per language —
/// `DateFormat` parses its skeleton on construction and a list builds many
/// rows.
abstract final class LedgerDates {
  static final Map<String, DateFormat> _times = <String, DateFormat>{};
  static final Map<String, DateFormat> _monthDays = <String, DateFormat>{};

  /// "10:12 AM" in [languageCode].
  static String time(String languageCode, DateTime at) => _times
      .putIfAbsent(languageCode, () => DateFormat.jm(languageCode))
      .format(at.toLocal());

  /// "Today", "Yesterday", "Sat, Sep 21" this year, "Fri, Aug 15, 2025"
  /// before that.
  static String dayTitle({
    required String languageCode,
    required LedgerDay<Object?> day,
    required DateTime now,
    required String today,
    required String yesterday,
  }) => switch (day.kindOn(now)) {
    LedgerDayKind.today => today,
    LedgerDayKind.yesterday => yesterday,
    LedgerDayKind.thisYear =>
      _monthDays
          .putIfAbsent(languageCode, () => DateFormat.MMMEd(languageCode))
          .format(day.date),
    LedgerDayKind.older => Formatters.date(languageCode, day.date),
  };
}
