import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/assistant_nudge_log.dart';

/// The device's memory of the assistant's greeting, launcher and tour.
abstract class AssistantNudgeRepository {
  /// [AssistantNudgeLog.empty] when nothing was stored yet.
  Future<Either<Failure, AssistantNudgeLog>> getLog();

  /// Applies [change] to the log as it is now and stores the result, which
  /// it answers. Changes made at the same time never overwrite each other
  /// (the tour opening while the greeting records how it ended), and an
  /// unchanged log is not written.
  Future<Either<Failure, AssistantNudgeLog>> updateLog(
    AssistantNudgeLog Function(AssistantNudgeLog log) change,
  );
}
