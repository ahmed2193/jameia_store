import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/account_overview.dart';

/// Read boundary for the account ("Mine") surfaces. Offline, both methods
/// resolve from the seeded catalogue; they still return `Either<Failure, T>` so
/// the presentation layer handles failure uniformly.
abstract class AccountRepository {
  /// Profile + quick-stat counts + unread badge for the Mine tab.
  Future<Either<Failure, AccountOverview>> getAccountOverview();

  /// The user's saved 4-digit delivery code (`getUserDeliveryCodeDetail`).
  Future<Either<Failure, String>> getDeliveryCode();
}
