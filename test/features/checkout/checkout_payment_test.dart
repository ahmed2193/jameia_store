// "Payment method": cash on delivery follows the store's switch, the wallet
// shows for a customer and is refused while it cannot cover the total, and a
// switch the page makes on the customer's behalf bumps the rows once.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/motion/change_bump.dart';
import 'package:hero_mart/src/core/widgets/option_row.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/checkout/domain/entities/checkout_store_rules.dart';
import 'package:hero_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_payment_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late FakeCheckoutRepository checkoutRepository;
  late CheckoutCubit checkoutCubit;
  late AuthSessionCubit session;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()
      ..snapshot = const CartSnapshot(
        // 2.600 to pay.
        cart: CartEntity(
          itemCount: 1,
          totals: CartTotalsEntity(
            subtotalFils: 2100,
            deliveryFeeFils: 500,
            totalFils: 2600,
          ),
        ),
        isRestored: true,
      );
    cartCubit = buildCartCubit(cartRepository);
    checkoutRepository = FakeCheckoutRepository();
    session = buildSessionCubit();
  });

  tearDown(() async {
    await checkoutCubit.close();
    await cartCubit.close();
    await session.close();
    await cartRepository.dispose();
  });

  void signIn({required int walletFils}) => session.signedIn(
    AuthCustomerEntity(id: 'c1', phone: '+96550000000', walletFils: walletFils),
  );

  Future<void> open(WidgetTester tester) async {
    checkoutCubit = buildCheckoutCubit(checkoutRepository);
    await checkoutCubit.start(defaultAddressId: 'a1');
    await pumpCheckoutSection(
      tester,
      const CheckoutPaymentSection(),
      cart: cartCubit,
      checkout: checkoutCubit,
      session: session,
    );
  }

  Finder cod() => find.widgetWithText(OptionRow, 'Cash on delivery');
  Finder wallet() => find.widgetWithText(OptionRow, 'Wallet');

  testWidgets('a guest pays cash on delivery; there is no wallet row', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Payment method'), findsOneWidget);
    expect(cod(), findsOneWidget);
    expect(wallet(), findsNothing);
    expect(find.text('Not available right now'), findsNothing);
  });

  testWidgets('cash on delivery off at the store: disabled and says so', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    checkoutRepository.rules = const CheckoutStoreRules(codEnabled: false);
    signIn(walletFils: 5000);
    await open(tester);

    expect(find.text('Not available right now'), findsOneWidget);
    expect(
      tester.getSemantics(cod()),
      isSemantics(
        hasCheckedState: true,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );

    // The wallet covers the order and can be picked; the disabled cash row
    // cannot take the choice back.
    await tester.tap(wallet());
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.draft.paymentMethod, OrderPaymentMethod.wallet);
    await tester.tap(cod());
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.draft.paymentMethod, OrderPaymentMethod.wallet);
    semantics.dispose();
  });

  testWidgets('a wallet short of the total is offered disabled', (
    tester,
  ) async {
    signIn(walletFils: 1000);
    await open(tester);

    expect(
      find.text('Balance KD 1.000 — not enough for this order'),
      findsOneWidget,
    );
    await tester.tap(wallet());
    await tester.pumpAndSettle();
    expect(checkoutCubit.state.draft.paymentMethod, OrderPaymentMethod.cod);
  });

  testWidgets('a switch made for the customer bumps the rows once', (
    tester,
  ) async {
    signIn(walletFils: 5000);
    checkoutCubit = buildCheckoutCubit(checkoutRepository);
    await checkoutCubit.start(defaultAddressId: 'a1');
    final ui = await pumpCheckoutSection(
      tester,
      const CheckoutPaymentSection(),
      cart: cartCubit,
      checkout: checkoutCubit,
      session: session,
    );
    ScaleTransition bump() => tester.widget<ScaleTransition>(
      find
          .descendant(
            of: find.byType(ChangeBump),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
    expect(bump().scale.value, 1);

    // What the page does after moving a short wallet back to cash.
    checkoutCubit.setPaymentMethod(OrderPaymentMethod.cod);
    ui.bumpPayment();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(bump().scale.value, greaterThan(1));

    await tester.pumpAndSettle();
    expect(bump().scale.value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduced motion: the bump is skipped', (tester) async {
    signIn(walletFils: 5000);
    checkoutCubit = buildCheckoutCubit(checkoutRepository);
    await checkoutCubit.start(defaultAddressId: 'a1');
    final ui = await pumpCheckoutSection(
      tester,
      const CheckoutPaymentSection(),
      cart: cartCubit,
      checkout: checkoutCubit,
      session: session,
      reduceMotion: true,
    );

    ui.bumpPayment();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
