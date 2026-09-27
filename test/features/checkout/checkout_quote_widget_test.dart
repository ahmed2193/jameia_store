// Until a destination is chosen the server has not priced the order for THIS
// mode, so the cart still carries the other mode's delivery fee. Quoting it
// would show a total that is about to move — up, if the customer started on
// pickup and switched to delivery. Pinned on the receipt ("Order totals").
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
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
    cartCubit = buildCartCubit(cartRepository);
    checkoutCubit = buildCheckoutCubit(FakeCheckoutRepository());
  });

  tearDown(() async {
    await checkoutCubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  Future<void> pump(WidgetTester tester) => pumpCheckoutSection(
    tester,
    const CheckoutReceipt(),
    cart: cartCubit,
    checkout: checkoutCubit,
  );

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
    expect(find.text('KD 0.500'), findsNothing);
    expect(find.text('—'), findsNWidgets(2));
  });
}
