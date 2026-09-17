import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

/// Live inbox feed (SSE): every new notification as the server emits it.
class WatchLiveNotificationsUseCase
    implements StreamUseCase<NotificationEntity, NoParams> {
  const WatchLiveNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  @override
  Stream<NotificationEntity> call(NoParams params) => _repository.watchLive();
}
