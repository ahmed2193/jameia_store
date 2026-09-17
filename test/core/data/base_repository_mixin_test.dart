import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/repositories/base_repository_mixin.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';

class _Repo with BaseRepositoryMixin {}

void main() {
  final repo = _Repo();

  test('maps each AppException to its Failure', () {
    expect(
      repo.mapToFailure(
        const UnauthorizedException('u', code: 'TOKEN_EXPIRED'),
      ),
      const UnauthorizedFailure('u'),
    );
    expect(
      repo.mapToFailure(const ForbiddenException('f')),
      const ForbiddenFailure('f'),
    );
    expect(
      repo.mapToFailure(
        const RateLimitedException(
          'slow down',
          retryAfter: Duration(seconds: 3),
        ),
      ),
      const RateLimitedFailure('slow down', retryAfter: Duration(seconds: 3)),
    );
    expect(
      repo.mapToFailure(const BadRequestException('bad', code: 'OUT_OF_STOCK')),
      const ServerFailure('bad', statusCode: 400, code: 'OUT_OF_STOCK'),
    );
    expect(
      repo.mapToFailure(
        const NotFoundException('nf', code: 'RESOURCE_NOT_FOUND'),
      ),
      const ServerFailure('nf', statusCode: 404, code: 'RESOURCE_NOT_FOUND'),
    );
    expect(
      repo.mapToFailure(
        const ServerException(
          'boom',
          statusCode: 503,
          code: 'SERVICE_UNAVAILABLE',
        ),
      ),
      const ServerFailure('boom', statusCode: 503, code: 'SERVICE_UNAVAILABLE'),
    );
    expect(
      repo.mapToFailure(const RequestTimeoutException()),
      const TimeoutFailure('Request timed out'),
    );
    expect(
      repo.mapToFailure(const NoInternetConnectionException()),
      const NetworkFailure('No internet connection'),
    );
    expect(
      repo.mapToFailure(const RequestCancelledException()),
      const NetworkFailure('Request cancelled'),
    );
    expect(
      repo.mapToFailure(const CacheException('c')),
      const CacheFailure('c'),
    );
    expect(
      repo.mapToFailure(const ParsingException('p')),
      const ParsingFailure('p'),
    );
  });

  test('execute wraps thrown exceptions into Left', () async {
    final result = await repo.execute<int>(
      () => throw const UnauthorizedException('expired'),
    );
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<UnauthorizedFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('unknown errors become UnexpectedFailure', () {
    expect(repo.mapToFailure(StateError('x')), isA<UnexpectedFailure>());
  });
}
