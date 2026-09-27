/// The stored form of the assistant greeting's log (`assistant.nudge.v1`):
/// moments as milliseconds since the epoch, absent when never set.
class AssistantNudgeLogModel {
  const AssistantNudgeLogModel({
    this.lastShownAtMs,
    this.lastOpenedAtMs,
    this.snoozedUntilMs,
    this.ignoredInARow = 0,
    this.launcherHiddenUntilMs,
    this.onboardedAtMs,
  });

  /// Anything unreadable falls back to "never" / `0`: a bad value must not
  /// cost more than one extra greeting.
  factory AssistantNudgeLogModel.fromJson(Map<String, dynamic> json) {
    int? moment(String key) => switch (json[key]) {
      final int value => value,
      _ => null,
    };
    return AssistantNudgeLogModel(
      lastShownAtMs: moment(lastShownKey),
      lastOpenedAtMs: moment(lastOpenedKey),
      snoozedUntilMs: moment(snoozedUntilKey),
      ignoredInARow: moment(ignoredInARowKey) ?? 0,
      launcherHiddenUntilMs: moment(launcherHiddenUntilKey),
      onboardedAtMs: moment(onboardedKey),
    );
  }

  static const String lastShownKey = 'lastShownAt';
  static const String lastOpenedKey = 'lastOpenedAt';
  static const String snoozedUntilKey = 'snoozedUntil';
  static const String ignoredInARowKey = 'ignoredInARow';
  static const String launcherHiddenUntilKey = 'launcherHiddenUntil';
  static const String onboardedKey = 'onboardedAt';

  final int? lastShownAtMs;
  final int? lastOpenedAtMs;
  final int? snoozedUntilMs;
  final int ignoredInARow;
  final int? launcherHiddenUntilMs;
  final int? onboardedAtMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
    lastShownKey: ?lastShownAtMs,
    lastOpenedKey: ?lastOpenedAtMs,
    snoozedUntilKey: ?snoozedUntilMs,
    ignoredInARowKey: ignoredInARow,
    launcherHiddenUntilKey: ?launcherHiddenUntilMs,
    onboardedKey: ?onboardedAtMs,
  };
}
