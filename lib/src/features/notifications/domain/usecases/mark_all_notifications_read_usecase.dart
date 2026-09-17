import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/notifications_repository.dart';

/// Marks every notification read; returns how many the server updated.
class MarkAllNotificationsReadUseCase implements UseCase<int, NoParams> {
  const MarkAllNotificationsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) =>
      _repository.markAllRead();
}
