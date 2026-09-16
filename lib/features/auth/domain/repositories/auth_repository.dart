import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Read boundary for the KeeTa `passport_login` flow. Offline there is no real
/// auth backend, so sign-in is a no-op that always succeeds (the seeded demo
/// profile is the "logged-in" user, resolved in the data layer). The domain
/// stays framework-free: no core `UserProfile` DTO crosses this boundary, and
/// since the presentation discards the profile the surface returns `Unit` on
/// success — still `Either<Failure, T>` so failure is handled uniformly.
abstract class AuthRepository {
  /// Sign in with a phone number (offline no-op parity — always succeeds).
  Future<Either<Failure, Unit>> login(String phone);
}
