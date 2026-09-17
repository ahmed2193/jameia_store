import 'package:equatable/equatable.dart';

/// Failures RETURNED by repositories inside `Either<Failure, T>`.
///
/// Clean-arch convention: repositories never let an exception escape —
/// `BaseRepositoryMixin` maps each `AppException` to the matching [Failure]
/// here, so the domain + presentation layers only ever see a `Failure` value.
///
/// UI guidance: a [ServerFailure] `message` is already localized by the backend
/// (`Accept-Language`) and can be shown as-is; the transport failures below
/// carry English fallbacks, so map THOSE to i18n keys in presentation.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Backend rejected the call. [code] is the stable `statusMessage` enum
/// (e.g. `OUT_OF_STOCK`, `VALIDATION_ERROR`) — branch on it, not on [message].
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode, this.code});

  final int? statusCode;
  final String? code;

  @override
  List<Object?> get props => [message, statusCode, code];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Forbidden']);
}

/// Rate limited after the automatic backoff retries were exhausted.
class RateLimitedFailure extends Failure {
  const RateLimitedFailure(super.message, {this.retryAfter});

  final Duration? retryAfter;

  @override
  List<Object?> get props => [message, retryAfter];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error']);
}

class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Could not parse data']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong']);
}
