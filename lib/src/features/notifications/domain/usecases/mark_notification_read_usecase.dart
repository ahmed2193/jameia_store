import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationReadParams extends Equatable {
  const MarkNotificationReadParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Marks one notification read; returns the server's updated copy.
class MarkNotificationReadUseCase
    implements UseCase<NotificationEntity, MarkNotificationReadParams> {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, NotificationEntity>> call(
    MarkNotificationReadParams params,
  ) => _repository.markRead(params.id);
}
