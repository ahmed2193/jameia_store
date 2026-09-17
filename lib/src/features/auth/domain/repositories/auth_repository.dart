import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../entities/otp_challenge.dart';
import '../entities/phone_number.dart';

/// Customer authentication over the jm3eia OTP flow. Tokens never cross this
/// boundary: the data layer persists them in the secure session store and the
/// network layer attaches them to every request.
///
/// Reference: https://docs.jm3eia.store/developers/auth.html
abstract class AuthRepository {
  /// `POST /v1/auth/send-otp` — start a login for [phone].
  Future<Either<Failure, OtpChallenge>> sendOtp(PhoneNumber phone);

  /// `POST /v1/auth/verify-otp` — exchange the code for a session. On success
  /// the token pair is stored and the guest identities are dropped.
  Future<Either<Failure, AuthCustomerEntity>> verifyOtp({
    required PhoneNumber phone,
    required String code,
  });

  /// Launch-time restore. `Right(null)` when no session is stored; otherwise
  /// the customer from `GET /v1/account/me` (Bearer attached, refreshed once on
  /// 401 by the network layer). `Left(UnauthorizedFailure)` when the session
  /// could not be refreshed — it is wiped; `Left(NetworkFailure)` etc. when
  /// offline — the stored session is kept.
  Future<Either<Failure, AuthCustomerEntity?>> restoreSession();

  /// `POST /v1/auth/logout` + local session wipe. The local wipe happens even
  /// when the server cannot be reached, so the user is always signed out.
  Future<Either<Failure, Unit>> logout();

  /// Fires when the network layer gave up refreshing an expired session.
  Stream<void> watchSessionExpiry();
}
