import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/settings_repository.dart';

/// Whether the app vibrates (haptic feedback). Vibration starts on: a
/// customer who never touched the switch feels it.
class GetHapticsEnabledUseCase implements SyncUseCase<bool, NoParams> {
  const GetHapticsEnabledUseCase(this._repository);

  final SettingsRepository _repository;

  /// The choice a customer has before touching the switch.
  static const bool enabledByDefault = true;

  @override
  Either<Failure, bool> call(NoParams params) =>
      _repository.hapticsEnabled().map((stored) => stored ?? enabledByDefault);
}
