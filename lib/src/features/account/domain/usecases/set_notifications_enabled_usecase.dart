import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/settings_repository.dart';

/// Turns push notifications on or off on this device.
class SetNotificationsEnabledUseCase
    implements UseCase<Unit, SetNotificationsEnabledParams> {
  const SetNotificationsEnabledUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetNotificationsEnabledParams params) =>
      _repository.setNotificationsEnabled(enabled: params.enabled);
}

class SetNotificationsEnabledParams extends Equatable {
  const SetNotificationsEnabledParams({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
