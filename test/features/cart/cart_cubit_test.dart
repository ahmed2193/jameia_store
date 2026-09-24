import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_item_request.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/add_cart_items_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/adjust_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/fetch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/flush_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/reset_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/restore_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_express_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_line_quantity_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/sync_cart_owner_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/watch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';

import 'cart_test_fixtures.dart';
import 'fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;
  late CartCubit cubit;

  CartCubit build() {
    repository = FakeCartRepository();
    return cubit = CartCubit(
      watch: WatchCartUseCase(repository),
      restore: RestoreCartUseCase(repository),
      syncOwner: SyncCartOwnerUseCase(repository),
      fetch: FetchCartUseCase(repository),
      flush: FlushCartUseCase(repository),
      adjustLine: AdjustCartLineUseCase(repository),
      setLineQuantity: SetCartLineQuantityUseCase(repository),
      removeLine: RemoveCartLineUseCase(repository),
      addItems: AddCartItemsUseCase(repository),
      clear: ClearCartUseCase(repository),
      applyCoupon: ApplyCartCouponUseCase(repository),
      removeCoupon: RemoveCartCouponUseCase(repository),
      applyLoyalty: ApplyCartLoyaltyUseCase(repository),
      removeLoyalty: RemoveCartLoyaltyUseCase(repository),
      setExpress: SetCartExpressUseCase(repository),
      reset: ResetCartUseCase(repository),
    );
  }

  /// Starts the cubit and lets the subscription deliver the first snapshot.
  Future<CartCubit> started() async {
    final cubit = build()..start();
    await Future<void>.delayed(Duration.zero);
    repository.calls.clear();
    return cubit;
  }

  CartSnapshot snapshotOf(int quantity) => CartSnapshot(
    cart: CartEntity(
      itemCount: quantity,
      lines: <CartLineEntity>[
        CartLineEntity(
          key: 'l1',
          product: testProduct,
          quantity: quantity,
          unitPriceFils: testProduct.priceFils,
          lineTotalFils: testProduct.priceFils * quantity,
        ),
      ],
    ),
    isRestored: true,
  );

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });
  test('start subscribes once and restores the device copy', () async {
    build()
      ..start()
      ..start();
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls.where((call) => call == 'restore'), hasLength(1));
  });

  test('a snapshot becomes the state with the per-product index', () async {
    final cubit = await started();

    repository.push(snapshotOf(3));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.totalQty, 3);
    expect(cubit.state.qtyOfProduct('p1'), 3);
    expect(cubit.state.isRestored, isTrue);
    expect(cubit.state.isEmpty, isFalse);
  });

  test('tile taps go through the line use cases', () async {
    final cubit = await started();
    repository.push(snapshotOf(2));
    await Future<void>.delayed(Duration.zero);
    repository.calls.clear();

    cubit
      ..addCatalogProduct(otherProduct, quantity: 2)
      ..removeProduct('p1')
      ..removeLine(cubit.state.cart.lines.single)
      ..setLineQuantity(cubit.state.cart.lines.single, 5);

    expect(repository.calls, <String>[
      'adjust:p2::2',
      'adjust:p1::-1',
      'remove:p1',
      'set:p1:5',
    ]);
  });

  test('a variant product without a variant never reaches the queue', () async {
    final cubit = await started();

    cubit.addCatalogProduct(
      const CatalogProductEntity(
        id: 'p9',
        slug: 'milk',
        name: 'Milk',
        type: CatalogProductType.variant,
      ),
    );

    expect(repository.calls, isEmpty);
    expect(cubit.state.failure, isA<ValidationFailure>());
  });
  test('a second server action is refused while one is running', () async {
    final cubit = await started();
    final gate = Completer<void>();
    repository.gate = gate;

    final first = cubit.applyCoupon('WELCOME');
    final second = await cubit.clear(); // refused: busy

    expect(second, isFalse);
    expect(cubit.state.busyAction, CartAction.coupon);
    gate.complete();
    expect(await first, isTrue);
    expect(cubit.state.busyAction, CartAction.none);
    expect(repository.calls, <String>['applyCoupon:WELCOME']);
  });

  test('a failed action keeps its failure and clears the busy flag', () async {
    final cubit = await started();
    repository.failure = const ServerFailure('nope', statusCode: 400);

    final applied = await cubit.applyLoyalty(50);

    expect(applied, isFalse);
    expect(cubit.state.failure, isA<ServerFailure>());
    expect(cubit.state.failedAction, CartAction.loyalty);
    expect(cubit.state.busyAction, CartAction.none);
  });

  test(
    'a coupon outside the API limits never reaches the repository',
    () async {
      final cubit = await started();

      expect(await cubit.applyCoupon('x'), isFalse);
      expect(repository.calls, isEmpty);
      expect(cubit.state.failure, isA<ValidationFailure>());
    },
  );

  test('the session hooks bind the mirror to the owner', () async {
    final cubit = await started();

    await cubit.onSignedIn('c1');
    await cubit.onGuestSession();
    await cubit.onSignedOut();
    await cubit.onLocaleChanged();
    await cubit.onOrderPlaced();

    expect(repository.calls, <String>[
      'syncOwner:c1',
      'syncOwner:guest',
      'syncOwner:guest',
      'fetch',
      'reset',
      'fetch',
    ]);
  });

  test('reorder sends every line of the order in one batch', () async {
    final cubit = await started();

    await cubit.addItems(const <CartItemRequest>[
      CartItemRequest(productId: 'p1', quantity: 2),
      CartItemRequest(productId: 'p2', quantity: 1),
    ]);

    expect(repository.calls, <String>['addItems:2']);
  });

  test('checkout flushes the pending taps', () async {
    final cubit = await started();

    expect(await cubit.prepareCheckout(), isTrue);
    expect(repository.calls, <String>['flush']);
  });

  test(
    'a refresh is not dropped while another cart action is in flight',
    () async {
      final cubit = await started();
      final gate = Completer<void>();
      repository.gate = gate;
      final express = cubit.setExpress(enabled: true);

      // Checkout re-prices the cart after a selection: this must reach the
      // server even though the express toggle is still in flight.
      final refreshed = await cubit.refresh();
      gate.complete();
      await express;

      expect(refreshed, isTrue);
      expect(repository.calls, contains('fetch'));
      await cubit.close();
    },
  );
}
