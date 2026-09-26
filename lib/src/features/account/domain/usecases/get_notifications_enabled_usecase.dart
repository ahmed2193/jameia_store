import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/settings_repository.dart';

/// Whether push notifications are on. Notifications start on: a customer who
/// never touched the switch gets them.
class GetNotificationsEnabledUseCase implements SyncUseCase<bool, NoParams> {
  const GetNotificationsEnabledUseCase(this._repository);

  final SettingsRepository _repository;

  /// The choice a customer has before touching the switch.
  static const bool enabledByDefault = true;

  @override
  Either<Failure, bool> call(NoParams params) => _repository
      .notificationsEnabled()
      .map((stored) => stored ?? enabledByDefault);
}
