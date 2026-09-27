import 'package:equatable/equatable.dart';

import 'assistant_nudge_outcome.dart';
import 'assistant_nudge_policy.dart';

/// What the device remembers about the assistant's greeting and launcher:
/// when the greeting last showed, when the customer last opened the chat,
/// how long it stays quiet, whether the launcher is hidden and whether the
/// customer has met the assistant (its tour). Pure: every change returns a
/// new log; [AssistantNudgePolicy] reads it.
class AssistantNudgeLog extends Equatable {
  const AssistantNudgeLog({
    this.lastShownAt,
    this.lastOpenedAt,
    this.snoozedUntil,
    this.ignoredInARow = 0,
    this.launcherHiddenUntil,
    this.onboardedAt,
  });

  /// Nothing recorded yet (a fresh install).
  static const AssistantNudgeLog empty = AssistantNudgeLog();

  final DateTime? lastShownAt;
  final DateTime? lastOpenedAt;

  /// No greeting before this moment (after a dismiss or repeated ignores).
  final DateTime? snoozedUntil;

  /// Greetings in a row that hid themselves untouched.
  final int ignoredInARow;

  /// The customer hid the floating launcher until this moment.
  final DateTime? launcherHiddenUntil;

  /// When the assistant's tour was first shown; `null` = never met.
  final DateTime? onboardedAt;

  /// The customer has seen the assistant's tour (finished or not).
  bool get isOnboarded => onboardedAt != null;

  bool isLauncherHiddenAt(DateTime at) {
    final until = launcherHiddenUntil;
    return until != null && at.isBefore(until);
  }

  AssistantNudgeLog shownAt(DateTime at) => _copy(lastShownAt: at);

  /// The log after a greeting (or the launcher) ended with [outcome] at [at].
  AssistantNudgeLog record(
    AssistantNudgeOutcome outcome,
    DateTime at, {
    AssistantNudgePolicy policy = const AssistantNudgePolicy(),
  }) => switch (outcome) {
    AssistantNudgeOutcome.opened => _copy(lastOpenedAt: at, ignoredInARow: 0),
    AssistantNudgeOutcome.dismissed => _copy(
      snoozedUntil: at.add(policy.dismissSnooze),
      ignoredInARow: 0,
    ),
    AssistantNudgeOutcome.ignored
        when ignoredInARow + 1 >= policy.ignoreLimit =>
      _copy(snoozedUntil: at.add(policy.ignoreBackOff), ignoredInARow: 0),
    AssistantNudgeOutcome.ignored => _copy(ignoredInARow: ignoredInARow + 1),
  };

  AssistantNudgeLog hideLauncherUntil(DateTime until) =>
      _copy(launcherHiddenUntil: until);

  /// The tour was shown at [at]; the first time is the one kept.
  AssistantNudgeLog onboarded(DateTime at) =>
      isOnboarded ? this : _copy(onboardedAt: at);

  AssistantNudgeLog _copy({
    DateTime? lastShownAt,
    DateTime? lastOpenedAt,
    DateTime? snoozedUntil,
    int? ignoredInARow,
    DateTime? launcherHiddenUntil,
    DateTime? onboardedAt,
  }) => AssistantNudgeLog(
    lastShownAt: lastShownAt ?? this.lastShownAt,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    ignoredInARow: ignoredInARow ?? this.ignoredInARow,
    launcherHiddenUntil: launcherHiddenUntil ?? this.launcherHiddenUntil,
    onboardedAt: onboardedAt ?? this.onboardedAt,
  );

  @override
  List<Object?> get props => [
    lastShownAt,
    lastOpenedAt,
    snoozedUntil,
    ignoredInARow,
    launcherHiddenUntil,
    onboardedAt,
  ];
}
