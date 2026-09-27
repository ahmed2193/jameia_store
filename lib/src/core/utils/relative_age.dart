import 'package:easy_localization/easy_localization.dart';

/// "Updated just now" / "Updated 5 minutes ago" / "… hours" / "… days", from
/// the i18n plurals (Arabic has all six forms) — never a hand-built string.
abstract final class RelativeAge {
  /// How long ago [savedAt] was, seen from [now]. A time in the future (the
  /// device clock moved back) reads "just now".
  static String updated(DateTime savedAt, {required DateTime now}) {
    final age = now.difference(savedAt);
    if (age.inMinutes < 1) return 'connectivity.updated_just_now'.tr();
    if (age.inHours < 1) {
      return plural('connectivity.updated_minutes', age.inMinutes);
    }
    if (age.inDays < 1) {
      return plural('connectivity.updated_hours', age.inHours);
    }
    return plural('connectivity.updated_days', age.inDays);
  }
}
