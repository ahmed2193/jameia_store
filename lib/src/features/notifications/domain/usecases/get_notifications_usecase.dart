import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notifications_feed.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsParams extends Equatable {
  const GetNotificationsParams({
    required this.page,
    required this.limit,
    this.unreadOnly = false,
  });

  /// 1-based.
  final int page;

  /// Backend cap is 100.
  final int limit;
  final bool unreadOnly;

  @override
  List<Object?> get props => [page, limit, unreadOnly];
}

/// One page of the inbox (plus the global unread counter).
class GetNotificationsUseCase
    implements UseCase<NotificationsFeed, GetNotificationsParams> {
  const GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, NotificationsFeed>> call(
    GetNotificationsParams params,
  ) => _repository.getNotifications(
    page: params.page,
    limit: params.limit,
    unreadOnly: params.unreadOnly,
  );
}
