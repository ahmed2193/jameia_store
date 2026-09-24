import 'dart:async';
import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../error/exceptions.dart';
import '../../error/failures.dart';

/// Shared error-mapping for every repository implementation.
///
/// Repositories `implements <Feature>Repository with BaseRepositoryMixin` and
/// wrap each datasource call in [execute] (async) or [executeSync] (sync), so
/// the `AppException → Failure` mapping lives in ONE place and no raw
/// exception ever reaches the domain or presentation layer.
///
/// ```dart
/// @override
/// Future<Either<Failure, List<CouponEntity>>> getCoupons() =>
///     execute(() => local.coupons().toEntities());
/// ```
mixin BaseRepositoryMixin {
  Future<Either<Failure, T>> execute<T>(FutureOr<T> Function() action) async {
    try {
      return Right(await action());
    } catch (error, stackTrace) {
      return Left(mapToFailure(error, stackTrace));
    }
  }

  Either<Failure, T> executeSync<T>(T Function() action) {
    try {
      return Right(action());
    } catch (error, stackTrace) {
      return Left(mapToFailure(error, stackTrace));
    }
  }

  /// Stream counterpart of [execute]: values pass through, every error is
  /// re-emitted as its [Failure], so a cubit listening to a repository stream
  /// branches on `UnauthorizedFailure` etc. and never sees an exception type.
  Stream<T> guardStream<T>(Stream<T> source) => source.transform(
    StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) =>
          sink.addError(mapToFailure(error, stackTrace), stackTrace),
    ),
  );

  /// Maps any thrown object to its [Failure]. Subtypes are matched before
  /// their parents (`UnauthorizedException` before `ServerException`), so keep
  /// the order when adding cases. Unknown errors are logged with their stack
  /// trace and surface as [UnexpectedFailure].
  Failure mapToFailure(Object error, [StackTrace? stackTrace]) {
    return switch (error) {
      UnauthorizedException(:final message) => UnauthorizedFailure(message),
      ForbiddenException(:final message) => ForbiddenFailure(message),
      RateLimitedException(:final message, :final retryAfter) =>
        RateLimitedFailure(message, retryAfter: retryAfter),
      NotFoundException(:final message, :final code) => NotFoundFailure(
        message,
        code: code,
      ),
      ServerException(:final message, :final statusCode, :final code) =>
        ServerFailure(message, statusCode: statusCode, code: code),
      RequestTimeoutException(:final message) => TimeoutFailure(message),
      NetworkException(:final message) => NetworkFailure(message),
      CacheException(:final message) => CacheFailure(message),
      ParsingException(:final message) => ParsingFailure(message),
      FormatException(:final message) => ParsingFailure(message),
      TypeError() => ParsingFailure(error.toString()),
      _ => _unexpected(error, stackTrace),
    };
  }

  Failure _unexpected(Object error, StackTrace? stackTrace) {
    log(
      'Unexpected repository error',
      name: runtimeType.toString(),
      error: error,
      stackTrace: stackTrace,
    );
    return UnexpectedFailure(error.toString());
  }
}
