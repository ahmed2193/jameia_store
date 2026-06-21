import 'package:equatable/equatable.dart';

/// Failures RETURNED by the domain layer inside `Either<Failure, T>`.
///
/// Clean-arch convention: repositories CATCH [exceptions] and map them to a
/// [Failure] here, so the domain + presentation layers only ever deal with a
/// `Failure` value (never a raw exception). Cubits read `failure.message` to
/// drive the error UI.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong']);
}
