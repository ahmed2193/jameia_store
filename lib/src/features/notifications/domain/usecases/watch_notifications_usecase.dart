import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notifications_feed.dart';
import '../repositories/notifications_repository.dart';

class WatchNotificationsParams extends Equatable {
  const WatchNotificationsParams({
    required this.limit,
    this.unreadOnly = false,
    this.forceRefresh = false,
  });

  /// Backend cap is 100.
  final int limit;
  final bool unreadOnly;

  /// Pull to refresh / reconnect: skip the saved copy.
  final bool forceRefresh;

  @override
  List<Object?> get props => [limit, unreadOnly, forceRefresh];
}

/// The first page of the inbox (plus the global unread counter): the copy
/// saved on the device first, then the server's; failures on the error
/// channel. The next pages are `GetNotificationsUseCase`'s — never kept.
class WatchNotificationsUseCase
    implements
        StreamUseCase<
          DataSnapshot<NotificationsFeed>,
          WatchNotificationsParams
        > {
  const WatchNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Stream<DataSnapshot<NotificationsFeed>> call(
    WatchNotificationsParams params,
  ) => _repository.watchFirstPage(
    limit: params.limit,
    unreadOnly: params.unreadOnly,
    forceRefresh: params.forceRefresh,
  );
}
