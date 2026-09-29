import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/settings_repository.dart';

/// Turns the app's vibration (haptic feedback) on or off on this device.
class SetHapticsEnabledUseCase
    implements UseCase<Unit, SetHapticsEnabledParams> {
  const SetHapticsEnabledUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetHapticsEnabledParams params) =>
      _repository.setHapticsEnabled(enabled: params.enabled);
}

class SetHapticsEnabledParams extends Equatable {
  const SetHapticsEnabledParams({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
