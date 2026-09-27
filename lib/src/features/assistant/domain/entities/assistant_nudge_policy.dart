import 'assistant_nudge_log.dart';

/// When the assistant may greet the customer on its own. Built on the
/// published defaults for proactive in-app messages (Zendesk / Intercom:
/// at most one a day; NN/g: never again right after a "no"):
/// - at most one greeting a day;
/// - none on a day the customer already opened the chat;
/// - a dismiss (X, swipe) keeps it quiet for [dismissSnooze];
/// - [ignoreLimit] greetings in a row left untouched back it off for
///   [ignoreBackOff].
class AssistantNudgePolicy {
  const AssistantNudgePolicy({
    this.dismissSnooze = const Duration(days: 3),
    this.ignoreLimit = 2,
    this.ignoreBackOff = const Duration(days: 7),
  });

  final Duration dismissSnooze;
  final int ignoreLimit;
  final Duration ignoreBackOff;

  bool allows(AssistantNudgeLog log, DateTime at) {
    final snoozedUntil = log.snoozedUntil;
    if (snoozedUntil != null && at.isBefore(snoozedUntil)) return false;
    return !_sameDay(log.lastShownAt, at) && !_sameDay(log.lastOpenedAt, at);
  }

  /// The next local midnight after [at] — "hide for today" lasts until then.
  static DateTime endOfDay(DateTime at) =>
      DateTime(at.year, at.month, at.day + 1);

  static bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}
