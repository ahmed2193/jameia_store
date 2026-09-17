// CheckoutCubit state-transition tests — exercises the P0 error-surfacing fix
// and puts the declared-but-unused `bloc_test` dependency to work.
//
// Before the fix a context-load failure left the screen on an infinite loader
// and a failed place-order commit was a silent no-op. These tests lock in that
// both failures now transition the cubit to `error` (which the screen renders as
// a retry / SnackBar), and that `retry()` re-runs the last `start()`.
//
// Post P2.9 refactor: the pass-through use cases were collapsed, so the cubit is
// constructed from the CheckoutRepository directly and its methods return the
// checkout feature's own framework-free entities (CheckoutContext /
// JameiaOrderEntity). The hand-written fake below mirrors that new boundary — no
// mocktail (not a project dependency); the project mocks by implementing the
// abstract repository, matching the original test's structure.

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jameia_mart/src/core/data/models/models.dart' show CartItem;
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_context.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/coupon_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/jameia_order_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/shop_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';

/// Configurable fake — each method returns its canned [Either], defaulting to a
/// [CacheFailure] so the failure paths need no fixtures. Implements the new
/// [CheckoutRepository] boundary the cubit now talks to directly.
class _FakeCheckoutRepo implements CheckoutRepository {
  _FakeCheckoutRepo({this.contextResult, this.placeResult});

  final Either<Failure, CheckoutContext>? contextResult;
  final Either<Failure, JameiaOrderEntity>? placeResult;

  int getContextCalls = 0;

  @override
  Future<Either<Failure, CheckoutContext>> getContext(String shopId) async {
    getContextCalls++;
    return contextResult ?? const Left(CacheFailure());
  }

  @override
  Future<Either<Failure, CouponEntity>> applyCoupon(String couponId) async =>
      const Left(CacheFailure());

  @override
  Future<Either<Failure, JameiaOrderEntity>> placeOrder({
    required ShopEntity shop,
    required List<CartItem> lines,
    required double subtotal,
    required CheckoutDraft draft,
  }) async => placeResult ?? const Left(CacheFailure());
}

/// The cubit's `placeOrder` now takes the feature's own [ShopEntity] (not the
/// core `Shop` DTO), so the snapshot passed in the commit test is one too.
const _shop = ShopEntity(
  id: 's1',
  name: 'Test Shop',
  logo: '',
  deliveryFee: 1.0,
  freeDelivery: false,
);

CheckoutCubit _build(_FakeCheckoutRepo repo) => CheckoutCubit(repository: repo);

void main() {
  group('CheckoutCubit', () {
    blocTest<CheckoutCubit, CheckoutState>(
      'start() failure emits loading then error (retry-able, not an infinite loader)',
      build: () => _build(
        _FakeCheckoutRepo(
          contextResult: const Left<Failure, CheckoutContext>(
            CacheFailure('boom'),
          ),
        ),
      ),
      act: (c) => c.start('s1'),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.status,
          'status',
          CheckoutStatus.loading,
        ),
        isA<CheckoutState>()
            .having((s) => s.status, 'status', CheckoutStatus.error)
            .having((s) => s.error, 'error', 'boom'),
      ],
    );

    blocTest<CheckoutCubit, CheckoutState>(
      'placeOrder() failure emits placing then error (surfaced, not a silent no-op)',
      build: () => _build(
        _FakeCheckoutRepo(
          placeResult: const Left<Failure, JameiaOrderEntity>(
            CacheFailure('nope'),
          ),
        ),
      ),
      act: (c) => c.placeOrder(shop: _shop, lines: const [], subtotal: 10),
      expect: () => [
        isA<CheckoutState>().having(
          (s) => s.status,
          'status',
          CheckoutStatus.placing,
        ),
        isA<CheckoutState>()
            .having((s) => s.status, 'status', CheckoutStatus.error)
            .having((s) => s.error, 'error', 'nope'),
      ],
    );

    test('retry() re-runs the last start() after a failure', () async {
      final repo = _FakeCheckoutRepo(
        contextResult: const Left<Failure, CheckoutContext>(CacheFailure()),
      );
      final cubit = _build(repo);
      await cubit.start('s1');
      await cubit.retry();
      expect(repo.getContextCalls, 2);
      await cubit.close();
    });
  });
}
