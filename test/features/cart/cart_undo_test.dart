// B3-03 Undo round trips on the cart page: a confirmed "Clear cart" is said
// with "Undo", which puts every line back in one request; a "−" that takes
// the last piece away says the line was removed, and "Undo" puts it back.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/pages/cart_tab_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_page_harness.dart';
import 'cart_test_fixtures.dart';
import 'fake_cart_repository.dart';

const Duration _tick = Duration(milliseconds: 16);

CartSnapshot _withRice(int quantity) => CartSnapshot(
  cart: CartEntity(
    itemCount: quantity,
    lines: <CartLineEntity>[
      CartLineEntity(
        key: 'l1',
        product: testProduct,
        quantity: quantity,
        unitPriceFils: 1500,
        lineTotalFils: 1500 * quantity,
      ),
    ],
  ),
  isRestored: true,
);

void main() {
  late FakeCartRepository repository;
  late CartCubit cart;
  late AuthSessionCubit session;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    Haptics.debugReset();
    repository = FakeCartRepository();
    cart = buildCartCubit(repository);
    session = buildGuestSession();
  });

  tearDown(() async {
    await session.close();
    await cart.close();
    await repository.dispose();
  });

  Future<void> pumpCart(WidgetTester tester, CartSnapshot snapshot) =>
      pumpCartHost(
        tester,
        repository: repository,
        cart: cart,
        session: session,
        snapshot: snapshot,
        // The clear dialog answers through go_router.
        router: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => CartTabPage(onBrowse: () {}),
            ),
          ],
        ),
      );

  testWidgets('a cleared cart says so with "Undo", which puts every line '
      'back in one request', (tester) async {
    await pumpCart(tester, _withRice(2));

    await tester.tap(find.text('Clear cart'));
    await tester.pump();
    await tester.pump(AppMotion.medium);
    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.pump(AppMotion.fast);
    // The server answered; the cart is empty now.
    await emitCartSnapshot(
      tester,
      repository,
      const CartSnapshot(isRestored: true),
    );
    await tester.pump(AppMotion.busyMinVisible);
    await tester.pump(AppMotion.medium);
    await tester.pump(_tick);

    expect(repository.calls, contains('clear'));
    expect(find.text('Cart cleared'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(AppMotion.fast);

    expect(repository.calls.last, 'addItems:1');
  });

  testWidgets('the last piece taken away: "Undo" puts the line back', (
    tester,
  ) async {
    await pumpCart(tester, _withRice(1));

    await tester.tap(find.byIcon(HeroIcons.trash));
    await tester.pump();
    await tester.pump(AppMotion.medium);
    await tester.pump(_tick);

    expect(repository.calls, contains('adjust:p1::-1'));
    expect(find.text('Basmati rice removed'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();

    expect(repository.calls.last, 'adjust:p1::1');
  });

  testWidgets('a "−" that leaves pieces in the cart says nothing', (
    tester,
  ) async {
    await pumpCart(tester, _withRice(2));

    await tester.tap(find.byIcon(HeroIcons.minus));
    await tester.pump();
    await tester.pump(AppMotion.medium);

    expect(repository.calls, contains('adjust:p1::-1'));
    expect(find.byType(SnackBar), findsNothing);
  });
}
