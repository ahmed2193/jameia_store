// Until a destination is chosen the server has not priced the order for THIS
// mode, so the cart still carries the other mode's delivery fee. Quoting it
// would show a total that is about to move — up, if the customer started on
// pickup and switched to delivery.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
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
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_branches_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/get_delivery_slots_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/place_order_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/select_delivery_address_usecase.dart';
import 'package:jameia_mart/src/features/checkout/domain/usecases/select_pickup_branch_usecase.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late FakeCheckoutRepository checkoutRepository;
  late CheckoutCubit checkoutCubit;

  /// 2.100 of goods with the delivery mode's 0.500 fee already in the total.
  const totals = CartTotalsEntity(
    subtotalFils: 2100,
    deliveryFeeFils: 500,
    baseDeliveryFeeFils: 500,
    totalFils: 2600,
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = const CartSnapshot(
        cart: CartEntity(itemCount: 1, totals: totals),
        isRestored: true,
      );
    cartCubit = CartCubit(
      watch: WatchCartUseCase(cartRepository),
      restore: RestoreCartUseCase(cartRepository),
      syncOwner: SyncCartOwnerUseCase(cartRepository),
      fetch: FetchCartUseCase(cartRepository),
      flush: FlushCartUseCase(cartRepository),
      adjustLine: AdjustCartLineUseCase(cartRepository),
      setLineQuantity: SetCartLineQuantityUseCase(cartRepository),
      removeLine: RemoveCartLineUseCase(cartRepository),
      addItems: AddCartItemsUseCase(cartRepository),
      clear: ClearCartUseCase(cartRepository),
      applyCoupon: ApplyCartCouponUseCase(cartRepository),
      removeCoupon: RemoveCartCouponUseCase(cartRepository),
      applyLoyalty: ApplyCartLoyaltyUseCase(cartRepository),
      removeLoyalty: RemoveCartLoyaltyUseCase(cartRepository),
      setExpress: SetCartExpressUseCase(cartRepository),
      reset: ResetCartUseCase(cartRepository),
    )..start();
    checkoutRepository = FakeCheckoutRepository();
    checkoutCubit = CheckoutCubit(
      getBranches: GetBranchesUseCase(checkoutRepository),
      getDeliverySlots: GetDeliverySlotsUseCase(checkoutRepository),
      selectDeliveryAddress: SelectDeliveryAddressUseCase(checkoutRepository),
      selectPickupBranch: SelectPickupBranchUseCase(checkoutRepository),
      placeOrder: PlaceOrderUseCase(checkoutRepository),
    );
  });

  tearDown(() async {
    await checkoutCubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CartCubit>.value(value: cartCubit),
              BlocProvider<CheckoutCubit>.value(value: checkoutCubit),
            ],
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: CheckoutSummary()),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('no destination yet quotes neither delivery nor total', (
    tester,
  ) async {
    await checkoutCubit.start();
    await pump(tester);

    // The goods are known; what the order costs is not.
    expect(find.text('KD 2.100'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('KD 2.600'), findsNothing);
    expect(find.text('KD 0.500'), findsNothing);
  });

  testWidgets('the total appears once the server priced the destination', (
    tester,
  ) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);

    expect(find.text('KD 2.100'), findsOneWidget);
    expect(find.text('KD 0.500'), findsOneWidget);
    expect(find.text('KD 2.600'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('switching to a mode with no destination drops the quote', (
    tester,
  ) async {
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pump(tester);
    expect(find.text('KD 2.600'), findsOneWidget);

    // Pickup, with no branch ever chosen: the 0.500 on the cart is the
    // delivery mode's, and the server has not re-priced yet.
    await checkoutCubit.setMode(FulfillmentMode.pickup);
    await tester.pumpAndSettle();

    expect(find.text('KD 2.600'), findsNothing);
    expect(find.text('—'), findsNWidgets(2));
  });
}
