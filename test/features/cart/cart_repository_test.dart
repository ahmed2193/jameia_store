import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_item_request.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_ref.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/cart/data/models/cart_mirror_model.dart';
import 'package:jameia_mart/src/features/cart/data/models/cart_model.dart';
import 'package:jameia_mart/src/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/domain/repositories/cart_repository.dart';

import 'cart_test_fakes.dart';
import 'cart_test_fixtures.dart';

void main() {
  late FakeCartRemoteDataSource remote;
  late FakeCartLocalDataSource local;
  late CartRepositoryImpl repository;

  /// Lets the debounce / retry / persist timers and their microtasks run.
  Future<void> settle([int turns = 6]) async {
    for (var i = 0; i < turns; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  CartRepositoryImpl build({
    Map<String, dynamic> Function(CartCall call, int index)? reply,
  }) {
    remote = FakeCartRemoteDataSource(reply ?? (_, _) => cartJson());
    local = FakeCartLocalDataSource();
    return repository = CartRepositoryImpl(
      remote,
      local,
      flushDelay: const Duration(milliseconds: 1),
      retryDelay: const Duration(milliseconds: 5),
      persistDelay: const Duration(milliseconds: 1),
    );
  }

  tearDown(() => repository.dispose());

  group('optimistic quantity changes', () {
    test('a tap shows at once and coalesces into ONE request', () async {
      build(
        reply: (_, _) =>
            cartJson(lines: <Map<String, dynamic>>[lineJson(quantity: 3)]),
      );

      repository.adjustLine(product: testProduct, delta: 1);
      repository.adjustLine(product: testProduct, delta: 1);
      repository.adjustLine(product: testProduct, delta: 1);

      // Visible before any request went out.
      expect(repository.snapshot.cart.itemCount, 3);
      expect(repository.snapshot.hasPendingChanges, isTrue);
      expect(remote.calls, isEmpty);

      await settle();

      expect(remote.calls.map((call) => call.name), <String>['addItems']);
      expect(remote.calls.single.items!.single['quantity'], 3);
      expect(repository.snapshot.hasPendingChanges, isFalse);
      expect(repository.snapshot.cart.lines.single.key, 'l1');
    });

    test('an existing line PATCHes its absolute target quantity', () async {
      build();
      await repository.fetch();
      await settle();
      remote.calls.clear();

      repository.adjustLine(product: testProduct, delta: 2);
      await settle();

      expect(remote.calls.single.name, 'patch');
      expect(remote.calls.single.key, 'l1');
      expect(remote.calls.single.quantity, 4); // the server had 2
    });

    test('removing a line DELETEs it', () async {
      build(
        reply: (call, _) => call.name == 'delete'
            ? cartJson(lines: <Map<String, dynamic>>[])
            : cartJson(),
      );
      await repository.fetch();
      await settle();
      remote.calls.clear();

      repository.removeLine(const CartLineRef('p1'));
      expect(repository.snapshot.cart.lines, isEmpty); // optimistic

      await settle();
      expect(remote.calls.single.name, 'delete');
      expect(repository.snapshot.cart.lines, isEmpty);
    });

    test('new products batch into one POST', () async {
      build();

      repository.adjustLine(product: testProduct, delta: 1);
      repository.adjustLine(product: otherProduct, delta: 2);
      await settle();

      expect(remote.calls.single.name, 'addItems');
      expect(remote.calls.single.items, hasLength(2));
    });

    test('taps during an in-flight request are rebased, not lost', () async {
      var quantity = 2;
      build(
        reply: (call, _) {
          if (call.name == 'patch') quantity = call.quantity!;
          return cartJson(
            lines: <Map<String, dynamic>>[lineJson(quantity: quantity)],
          );
        },
      );
      await repository.fetch();
      await settle();
      remote.calls.clear();

      final gate = Completer<void>();
      remote.gate = gate;
      repository.adjustLine(product: testProduct, delta: 1); // target 3
      await settle(3);
      // That PATCH is in flight; two more taps land meanwhile.
      repository.adjustLine(product: testProduct, delta: 1);
      repository.adjustLine(product: testProduct, delta: 1);
      expect(repository.snapshot.cart.itemCount, 5);
      gate.complete();
      await settle();

      // The leftover went out as ONE absolute follow-up.
      expect(remote.calls.map((call) => call.quantity), <int>[3, 5]);
      expect(repository.snapshot.cart.itemCount, 5);
      expect(repository.snapshot.hasPendingChanges, isFalse);
    });
  });
  group('failures', () {
    test('offline keeps the change, flags it and retries', () async {
      var fail = true;
      build(
        reply: (call, _) {
          if (fail) throw const NoInternetConnectionException();
          return cartJson(lines: <Map<String, dynamic>>[lineJson(quantity: 1)]);
        },
      );

      repository.adjustLine(product: testProduct, delta: 1);
      await settle();

      expect(repository.snapshot.isUnsynced, isTrue);
      expect(repository.snapshot.hasPendingChanges, isTrue);
      expect(repository.snapshot.failure, isA<NetworkFailure>());
      expect(repository.snapshot.cart.itemCount, 1); // still shown

      fail = false;
      await settle(10);

      expect(repository.snapshot.isUnsynced, isFalse);
      expect(repository.snapshot.hasPendingChanges, isFalse);
    });

    test('a connection that stays down backs the retry off', () async {
      build(
        reply: (call, _) {
          throw const NoInternetConnectionException();
        },
      );

      repository.adjustLine(product: testProduct, delta: 1);
      // retryDelay is 5 ms here, so a fixed-interval retry would fire ~20
      // times in 100 ms; doubling gets 5 + 10 + 20 + 40 through it.
      await settle(50);

      expect(repository.snapshot.isUnsynced, isTrue);
      expect(
        remote.calls.length,
        lessThan(10),
        reason: 'the retry must back off, not hammer a dead connection',
      );
      expect(remote.calls.length, greaterThan(1), reason: 'it must retry');
    });

    test(
      'a tap after a failure retries at once instead of the back-off',
      () async {
        var fail = true;
        build(
          reply: (call, _) {
            if (fail) throw const NoInternetConnectionException();
            return cartJson(
              lines: <Map<String, dynamic>>[lineJson(quantity: 2)],
            );
          },
        );

        repository.adjustLine(product: testProduct, delta: 1);
        await settle(40); // several failed attempts: the wait is now long
        final attempts = remote.calls.length;

        fail = false;
        repository.adjustLine(product: testProduct, delta: 1);
        await settle(6); // shorter than the backed-off wait

        expect(remote.calls.length, greaterThan(attempts));
        expect(repository.snapshot.isUnsynced, isFalse);
        expect(repository.snapshot.hasPendingChanges, isFalse);
      },
    );

    test('an OUT_OF_STOCK rejection drops the change and refetches', () async {
      build(
        reply: (call, _) {
          if (call.name == 'addItems') {
            throw const BadRequestException(
              'Out of stock',
              code: 'OUT_OF_STOCK',
            );
          }
          return cartJson(lines: <Map<String, dynamic>>[]);
        },
      );

      repository.adjustLine(product: testProduct, delta: 1);
      await settle();

      expect(remote.calls.map((call) => call.name), <String>[
        'addItems',
        'get',
      ]);
      expect(repository.snapshot.hasPendingChanges, isFalse);
      expect(repository.snapshot.isUnsynced, isFalse);
      expect(repository.snapshot.cart.lines, isEmpty);
      expect(repository.snapshot.failure, isA<ServerFailure>());
      expect(repository.snapshot.failedAction, CartAction.sync);
    });

    test('a refused coupon reports the failure on the snapshot', () async {
      build(
        reply: (call, _) {
          if (call.name == 'applyCoupon') {
            throw const BadRequestException(
              'This coupon is not valid',
              code: 'COUPON_INVALID',
            );
          }
          return cartJson();
        },
      );
      final seen = <CartSnapshot>[];
      final subscription = repository.watch().listen(seen.add);

      final result = await repository.applyCoupon('NOPE99');
      await settle();

      expect(result.isLeft(), isTrue);
      // The stream is what the cubit listens to, and it is asynchronous: a
      // snapshot WITHOUT the failure would land after the Either and wipe
      // the message the sheet is waiting to show.
      final last = seen.last;
      expect(last.failure, isA<ServerFailure>());
      expect(last.failedAction, CartAction.coupon);
      await subscription.cancel();
    });

    test('a refused loyalty redemption names the loyalty action', () async {
      build(
        reply: (call, _) {
          if (call.name == 'applyLoyalty') {
            throw const BadRequestException('Not enough points');
          }
          return cartJson();
        },
      );
      final seen = <CartSnapshot>[];
      final subscription = repository.watch().listen(seen.add);

      await repository.applyLoyalty(500);
      await settle();

      expect(seen.last.failedAction, CartAction.loyalty);
      await subscription.cancel();
    });
    test('clear rolls back when the server refuses', () async {
      build(
        reply: (call, _) {
          if (call.name == 'clear') {
            throw const ServerException('boom', statusCode: 500);
          }
          return cartJson();
        },
      );
      await repository.fetch();
      await settle();

      final result = await repository.clear();
      await settle();

      expect(result.isLeft(), isTrue);
      expect(repository.snapshot.cart.lines, hasLength(1)); // rolled back
    });

    test('a fetch failure maps to its Failure', () async {
      build(reply: (_, _) => throw const RequestTimeoutException());

      final result = await repository.fetch();

      expect(
        result.fold((failure) => failure, (_) => null),
        isA<TimeoutFailure>(),
      );
    });
  });
  group('session and device mirror', () {
    test('restore paints the saved cart and its pending changes', () async {
      build();
      local.mirror = CartMirrorModel(
        ownerId: CartRepository.guestOwnerId,
        cart: CartModel.fromJson(cartJson()),
        pending: const <CartPendingChangeModel>[
          CartPendingChangeModel(productId: 'p1', delta: 1),
        ],
      );

      await repository.restore();

      expect(repository.snapshot.isRestored, isTrue);
      expect(repository.snapshot.cart.itemCount, 3); // 2 server + 1 pending
      expect(repository.snapshot.hasPendingChanges, isTrue);
      expect(remote.calls, isEmpty); // nothing hit the network
    });

    test('an unreadable mirror is dropped, not fatal', () async {
      build();
      local
        ..mirror = const CartMirrorModel(ownerId: 'c1')
        ..readError = const CacheException('corrupt');

      final result = await repository.restore();

      expect(result.isRight(), isTrue);
      expect(local.clears, 1);
      expect(repository.snapshot.isRestored, isTrue);
    });

    test('signing in keeps the guest taps and flushes them', () async {
      build();

      repository.adjustLine(product: testProduct, delta: 1);
      await repository.syncOwner('c1');
      await settle();

      expect(remote.calls.first.name, 'get');
      expect(remote.calls.any((call) => call.name != 'get'), isTrue);
      expect(local.mirror?.ownerId, 'c1');
    });

    test('a mirror of another customer is dropped on sign-in', () async {
      build();
      local.mirror = CartMirrorModel(
        ownerId: 'c1',
        cart: CartModel.fromJson(cartJson()),
        pending: const <CartPendingChangeModel>[
          CartPendingChangeModel(productId: 'p1', delta: 5),
        ],
      );
      await repository.restore();

      await repository.syncOwner('c2');
      await settle();

      expect(repository.snapshot.hasPendingChanges, isFalse);
      expect(remote.calls.map((call) => call.name), contains('get'));
    });

    test('reset forgets the cart and ignores replies in flight', () async {
      build();
      await repository.fetch();
      await settle();

      final gate = Completer<void>();
      remote.gate = gate;
      repository.adjustLine(product: testProduct, delta: 1);
      await settle(3);
      await repository.reset();
      gate.complete();
      await settle();

      expect(repository.snapshot.cart.lines, isEmpty);
      expect(repository.snapshot.hasPendingChanges, isFalse);
      expect(local.clears, greaterThan(0));
    });

    test('the cart token of a reply is remembered', () async {
      build();
      await repository.fetch();
      await settle();

      expect(local.cartToken, 'ct-1');
    });

    test('the mirror is written after a change settles', () async {
      build();
      repository.adjustLine(product: testProduct, delta: 1);
      await settle();

      expect(local.saves, greaterThan(0));
      expect(local.mirror?.cart?.cartToken, 'ct-1');
    });
  });

  group('server-confirmed operations', () {
    test('addItems sends the rows it is given in one request', () async {
      build();

      // What is worth sending is the use case's rule (validity, the
      // per-request cap): see add_cart_items_usecase_test.dart.
      final result = await repository.addItems(const <CartItemRequest>[
        CartItemRequest(productId: 'p1', quantity: 2),
        CartItemRequest(productId: 'p2', quantity: 1),
      ]);

      expect(result.isRight(), isTrue);
      expect(remote.calls.single.items, hasLength(2));
    });

    test('a coupon flushes the pending taps first', () async {
      build();
      repository.adjustLine(product: testProduct, delta: 1);

      await repository.applyCoupon('WELCOME');

      expect(remote.calls.map((call) => call.name), <String>[
        'addItems',
        'applyCoupon',
      ]);
    });

    test('watch replays the current snapshot to a new listener', () async {
      build();
      await repository.fetch();
      await settle();

      final first = await repository.watch().first;

      expect(first.cart.lines, hasLength(1));
    });
  });

  group('a failed read never leaves the cart stuck', () {
    test('a failed fetch clears isSyncing', () async {
      build(reply: (_, _) => throw const RequestTimeoutException('slow'));

      final result = await repository.fetch();
      await settle();

      expect(result.isLeft(), isTrue);
      // Otherwise the totals keep saying "updating" and checkout stays
      // disabled for the rest of the session.
      expect(repository.snapshot.isSyncing, isFalse);
    });

    test('a reset while a request is in flight clears isSyncing', () async {
      build();
      final gate = Completer<void>();
      remote.gate = gate;
      final inFlight = repository.fetch();

      await repository.reset();
      gate.complete();
      await inFlight;
      await settle();

      expect(repository.snapshot.isSyncing, isFalse);
    });

    test('taps kept through a failed syncOwner are retried', () async {
      build(
        reply: (call, _) => call.name == 'get'
            ? throw const NoInternetConnectionException('offline')
            : cartJson(lines: <Map<String, dynamic>>[lineJson(quantity: 1)]),
      );
      repository.adjustLine(product: testProduct, delta: 1);

      await repository.syncOwner('c1');

      expect(repository.snapshot.isUnsynced, isTrue);
      // The retry sends the tap without waiting for another one.
      await settle(12);
      expect(remote.calls.map((call) => call.name), contains('addItems'));
      expect(repository.snapshot.isUnsynced, isFalse);
    });

    test('a clear abandoned by a reset is not an error for the UI', () async {
      build();
      final gate = Completer<void>();
      remote.gate = gate;
      final clearing = repository.clear();

      await repository.reset();
      gate.complete();
      final result = await clearing;

      expect(
        result.isRight(),
        isTrue,
        reason: 'the cart was dropped on purpose',
      );
    });

    test('a coupon is not applied while the taps could not go out', () async {
      build(
        reply: (call, _) => call.name == 'addItems'
            ? throw const NoInternetConnectionException('offline')
            : cartJson(),
      );
      repository.adjustLine(product: testProduct, delta: 1);

      final result = await repository.applyCoupon('WELCOME');

      expect(result.isLeft(), isTrue);
      expect(
        remote.calls.map((call) => call.name),
        isNot(contains('applyCoupon')),
        reason: 'it would price a cart the customer no longer sees',
      );
    });
  });
}
