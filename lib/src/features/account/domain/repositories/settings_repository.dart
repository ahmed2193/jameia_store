import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Device-level settings of the Settings screen. Nothing here is on the
/// jm3eia backend (no preference route exists), so it all lives on the
/// device.
abstract class SettingsRepository {
  /// The stored push-notification choice, or `null` when the customer never
  /// changed it.
  Either<Failure, bool?> notificationsEnabled();

  /// Stores the push-notification choice.
  Future<Either<Failure, Unit>> setNotificationsEnabled({
    required bool enabled,
  });

  /// Empties the on-disk image cache.
  Future<Either<Failure, Unit>> clearCache();
}
