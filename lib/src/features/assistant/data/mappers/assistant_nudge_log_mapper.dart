import '../../domain/entities/assistant_nudge_log.dart';
import '../models/assistant_nudge_log_model.dart';

extension AssistantNudgeLogMapper on AssistantNudgeLogModel {
  AssistantNudgeLog toEntity() => AssistantNudgeLog(
    lastShownAt: _moment(lastShownAtMs),
    lastOpenedAt: _moment(lastOpenedAtMs),
    snoozedUntil: _moment(snoozedUntilMs),
    ignoredInARow: ignoredInARow,
    launcherHiddenUntil: _moment(launcherHiddenUntilMs),
    onboardedAt: _moment(onboardedAtMs),
  );

  static DateTime? _moment(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

extension AssistantNudgeLogToModel on AssistantNudgeLog {
  AssistantNudgeLogModel toModel() => AssistantNudgeLogModel(
    lastShownAtMs: lastShownAt?.millisecondsSinceEpoch,
    lastOpenedAtMs: lastOpenedAt?.millisecondsSinceEpoch,
    snoozedUntilMs: snoozedUntil?.millisecondsSinceEpoch,
    ignoredInARow: ignoredInARow,
    launcherHiddenUntilMs: launcherHiddenUntil?.millisecondsSinceEpoch,
    onboardedAtMs: onboardedAt?.millisecondsSinceEpoch,
  );
}
