import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_overview.dart';
import '../entities/profile_update.dart';

/// Read/write boundary for the account ("Mine") surfaces.
///
/// The overview + delivery code still resolve from the seeded offline
/// catalogue; the profile lives on the jm3eia backend (customer Bearer):
/// https://docs.jm3eia.store/developers/account.html
abstract class AccountRepository {
  /// Profile + quick-stat counts + unread badge for the Mine tab (offline).
  Future<Either<Failure, AccountOverview>> getAccountOverview();

  /// The user's saved 4-digit delivery code (`getUserDeliveryCodeDetail`).
  Future<Either<Failure, String>> getDeliveryCode();

  /// `GET /v1/account/me` — the live customer record. `UnauthorizedFailure`
  /// when signed out.
  Future<Either<Failure, AuthCustomerEntity>> getProfile();

  /// `PATCH /v1/account/profile` with only the changed fields; resolves to
  /// the updated customer.
  Future<Either<Failure, AuthCustomerEntity>> updateProfile(
    ProfileUpdate update,
  );
}
