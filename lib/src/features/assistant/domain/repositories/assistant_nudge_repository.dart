import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/assistant_nudge_log.dart';

/// The device's memory of the assistant's greeting and launcher.
abstract class AssistantNudgeRepository {
  /// [AssistantNudgeLog.empty] when nothing was stored yet.
  Future<Either<Failure, AssistantNudgeLog>> getLog();

  Future<Either<Failure, Unit>> saveLog(AssistantNudgeLog log);
}
