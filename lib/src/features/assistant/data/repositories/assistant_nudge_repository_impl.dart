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

  @override
  Future<Either<Failure, Unit>> saveLog(AssistantNudgeLog log) =>
      execute(() async {
        await _local.write(log.toModel());
        return unit;
      });
}
