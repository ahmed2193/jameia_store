import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/assistant_nudge_log.dart';
import '../../domain/repositories/assistant_nudge_repository.dart';
import '../datasources/assistant_nudge_local_data_source.dart';
import '../mappers/assistant_nudge_log_mapper.dart';

class AssistantNudgeRepositoryImpl
    with BaseRepositoryMixin
    implements AssistantNudgeRepository {
  const AssistantNudgeRepositoryImpl(this._local);

  final AssistantNudgeLocalDataSource _local;

  @override
  Future<Either<Failure, AssistantNudgeLog>> getLog() =>
      execute(() => _local.read().toEntity());

  // The read and the change run before the first await, and the store
  // keeps what it was handed at once: a second change made meanwhile reads
  // this one's result instead of the log both started from.
  @override
  Future<Either<Failure, AssistantNudgeLog>> updateLog(
    AssistantNudgeLog Function(AssistantNudgeLog log) change,
  ) => execute(() async {
    final current = _local.read().toEntity();
    final next = change(current);
    if (next != current) await _local.write(next.toModel());
    return next;
  });
}
