// CartState.changedBy through the REAL repository and cubit: the snapshot a
// server-confirmed action brings lands AFTER the action's own result (the
// stream is asynchronous), so the busy flag is already cleared by then. The
// state that carries the new cart must still say which action caused it —
// the checkout tells "the customer removed the coupon" from "the server
// dropped it" by this.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/add_cart_items_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/adjust_cart_line_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/apply_cart_coupon_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/apply_cart_loyalty_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/fetch_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/flush_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/remove_cart_coupon_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/remove_cart_line_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/remove_cart_loyalty_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/reset_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/restore_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/set_cart_express_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/set_cart_line_quantity_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/sync_cart_owner_usecase.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/watch_cart_usecase.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_state.dart';

import 'cart_test_fakes.dart';
import 'cart_test_fixtures.dart';

void main() {
  late CartRepositoryImpl repository;
  late CartCubit cubit;
  var hasCoupon = true;
  var express = true;

  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  setUp(() async {
    hasCoupon = true;
    express = true;
    final remote = FakeCartRemoteDataSource((call, _) {
      if (call.name == 'removeCoupon') hasCoupon = false;
      if (call.name == 'express') express = call.quantity == 1;
      final json = cartJson(
        coupon: hasCoupon
            ? <String, dynamic>{'code': 'SAVE3', 'discount': 300}
            : null,
      );
      json['expressSelected'] = express;
      return json;
    });
    repository = CartRepositoryImpl(
      remote,
      FakeCartLocalDataSource(),
      flushDelay: const Duration(milliseconds: 1),
      retryDelay: const Duration(milliseconds: 5),
      persistDelay: const Duration(milliseconds: 1),
    );
    cubit = CartCubit(
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
    )..start();
    await repository.fetch();
    await settle();
  });

  tearDown(() async {
    await cubit.close();
    repository.dispose();
  });

  test(
    'the cart a coupon removal brings is marked as the coupon action',
    () async {
      expect(cubit.state.cart.coupon?.code, 'SAVE3');
      final states = <CartState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.removeCoupon();
      await settle();
      await sub.cancel();

      final landed = states.firstWhere((state) => state.cart.coupon == null);
      // Busy was already cleared before this cart arrived …
      expect(landed.busyAction, CartAction.none);
      // … but the state still names what brought it.
      expect(landed.changedBy, CartAction.coupon);
    },
  );

  test(
    'the cart an express switch brings is marked as the express action',
    () async {
      expect(cubit.state.cart.expressSelected, isTrue);
      final states = <CartState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.setExpress(enabled: false);
      await settle();
      await sub.cancel();

      final landed = states.firstWhere((state) => !state.cart.expressSelected);
      expect(landed.changedBy, CartAction.express);
    },
  );

  test('a plain re-read is not marked as an action', () async {
    final states = <CartState>[];
    final sub = cubit.stream.listen(states.add);

    hasCoupon = false;
    await cubit.refresh();
    await settle();
    await sub.cancel();

    final landed = states.firstWhere((state) => state.cart.coupon == null);
    expect(landed.changedBy, CartAction.none);
  });
}
