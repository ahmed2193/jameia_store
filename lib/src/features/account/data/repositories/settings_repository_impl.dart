import 'package:dartz/dartz.dart';

import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl
    with BaseRepositoryMixin
    implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);

  final SettingsLocalDataSource _local;

  @override
  Either<Failure, bool?> notificationsEnabled() =>
      executeSync(_local.notificationsEnabled);

  @override
  Future<Either<Failure, Unit>> setNotificationsEnabled({
    required bool enabled,
  }) => execute(() async {
    await _local.setNotificationsEnabled(enabled: enabled);
    return unit;
  });

  @override
  Either<Failure, bool?> hapticsEnabled() => executeSync(_local.hapticsEnabled);

  @override
  Future<Either<Failure, Unit>> setHapticsEnabled({required bool enabled}) =>
      execute(() async {
        await _local.setHapticsEnabled(enabled: enabled);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> clearCache() => execute(() async {
    await _local.clearCache();
    return unit;
  });
}
