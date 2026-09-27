// The pinned place-order bar on its own (G5): the rolling total and its
// struck twin, the fact line (a blocking reason stays put; the savings and
// delivery facts rotate without rebuilding the bar), "Place order" and what a
// tap on it says while it is disabled, the flight target, the title bar's
// subtitle, and the savings hint that rides on the button.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_coupon_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/motion/float_loop.dart';
import 'package:jameia_mart/src/core/motion/fly_to_cart.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/core/motion/rolling_number.dart';
import 'package:jameia_mart/src/core/motion/rotating_line.dart';
import 'package:jameia_mart/src/core/widgets/connectivity_scope.dart';
import 'package:jameia_mart/src/core/widgets/jameia_money_text.dart';
import 'package:jameia_mart/src/core/widgets/jameia_submit_button.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_block_reason.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_cubit.dart';
import 'package:jameia_mart/src/features/checkout/presentation/cubit/checkout_state.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_fact_text.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_line.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_bar_total.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_hint_bubble.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_button.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_place_order_bar.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_savings_hint.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_title_bar.dart';
import 'package:jameia_mart/src/features/checkout/presentation/widgets/checkout/checkout_ui_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import '../cart/cart_test_fixtures.dart';
import '../cart/fake_cart_repository.dart';
import 'checkout_test_harness.dart';
import 'fake_checkout_repository.dart';

/// The bar at the bottom of a screen with the savings hint over it — how
/// the body stacks them (the hint follows the button through the page's
/// layer link, so it needs room above the bar).
class _BarWithHint extends StatelessWidget {
  const _BarWithHint();

  static const double _height = 420;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _height,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(child: SizedBox.shrink()),
              CheckoutPlaceOrderBar(),
            ],
          ),
          CheckoutSavingsHint(),
        ],
      ),
    );
  }
}

void main() {
  late FakeCartRepository cartRepository;
  late CartCubit cartCubit;
  late FakeCheckoutRepository checkoutRepository;
  late CheckoutCubit checkoutCubit;

  const rice = CartLineEntity(
    key: 'l1',
    product: testProduct,
    quantity: 2,
    unitPriceFils: 600,
    lineTotalFils: 1200,
  );

  /// Rice on sale: 0.300 off each of its 2 pieces.
  const riceOnSale = CartLineEntity(
    key: 'l1',
    product: testProduct,
    quantity: 2,
    unitPriceFils: 600,
    compareAtFils: 900,
    lineTotalFils: 1200,
  );
  const oil = CartLineEntity(
    key: 'l2',
    product: otherProduct,
    quantity: 1,
    unitPriceFils: 900,
    lineTotalFils: 900,
  );

  /// 2.100 of goods; the delivery fee (0.500) is in the total unless
  /// delivery is free.
  CartSnapshot snapshot({
    List<CartLineEntity> lines = const [rice, oil],
    int subtotalFils = 2100,
    bool freeDelivery = false,
    bool meetsMinOrder = true,
    int minOrderFils = 0,
    CartCouponEntity? coupon,
    int couponDiscountFils = 0,
    bool pending = false,
    bool unsynced = false,
  }) {
    final delivery = freeDelivery ? 0 : 500;
    return CartSnapshot(
      cart: CartEntity(
        itemCount: 3,
        lines: lines,
        coupon: coupon,
        totals: CartTotalsEntity(
          subtotalFils: subtotalFils,
          couponDiscountFils: couponDiscountFils,
          discountFils: couponDiscountFils,
          deliveryFeeFils: delivery,
          baseDeliveryFeeFils: 500,
          freeDelivery: freeDelivery,
          minOrderFils: minOrderFils,
          meetsMinOrder: meetsMinOrder,
          totalFils: subtotalFils - couponDiscountFils + delivery,
        ),
      ),
      isRestored: true,
      hasPendingChanges: pending,
      isUnsynced: unsynced,
    );
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    cartRepository = FakeCartRepository()..snapshot = snapshot();
    cartCubit = buildCartCubit(cartRepository);
    checkoutRepository = FakeCheckoutRepository();
    checkoutCubit = buildCheckoutCubit(checkoutRepository);
  });

  tearDown(() async {
    await checkoutCubit.close();
    await cartCubit.close();
    await cartRepository.dispose();
  });

  Finder inBar(Finder matching) => find.descendant(
    of: find.byType(CheckoutPlaceOrderBar),
    matching: matching,
  );

  Future<CheckoutUiController> pumpBar(
    WidgetTester tester, {
    Widget child = const CheckoutPlaceOrderBar(),
    Locale locale = checkoutEn,
    Size size = const Size(480, 2400),
    double textScale = 1,
  }) => pumpCheckoutSection(
    tester,
    child,
    cart: cartCubit,
    checkout: checkoutCubit,
    inScrollView: false,
    locale: locale,
    size: size,
    textScale: textScale,
  );

  /// Pushes a cart snapshot the way the repository stream delivers it.
  Future<void> emit(WidgetTester tester, CartSnapshot next) async {
    await tester.runAsync(() async {
      cartRepository.push(next);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  /// Feeds the cart a snapshot before the bar is pumped (the cubit is
  /// already listening; the next await delivers it).
  void useCart(CartSnapshot next) => cartRepository.push(next);

  /// Counts the haptics the platform is asked for.
  List<Object?> recordHaptics(WidgetTester tester) {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return haptics;
  }

  Future<void> tapPlaceOrder(WidgetTester tester) async {
    await tester.tap(find.byType(JameiaSubmitButton));
    await tester.pump();
  }

  group('total', () {
    testWidgets('one dash until priced; the total reads out after the select', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpBar(tester);

      expect(inBar(find.text('—')), findsOneWidget);
      expect(inBar(find.bySemanticsLabel('KD 2.600')), findsNothing);
      expect(find.text('Choose an address to see the total'), findsOneWidget);

      await checkoutCubit.start(defaultAddressId: 'a1');
      await tester.pumpAndSettle();

      expect(inBar(find.bySemanticsLabel('KD 2.600')), findsOneWidget);
      expect(inBar(find.byType(RollingNumber)), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'CT-B1: says Updating… while the cart re-prices, then rolls in place',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await checkoutCubit.start(defaultAddressId: 'a1');
        await pumpBar(tester);
        final roller = inBar(find.byType(RollingNumber));
        final before = tester.element(roller);

        await emit(tester, snapshot(pending: true));
        await tester.pumpAndSettle();
        expect(inBar(find.bySemanticsLabel('Updating…')), findsOneWidget);
        expect(find.semantics.byLabel('KD 2.600'), findsNothing);

        await emit(tester, snapshot(subtotalFils: 2400));
        await tester.pumpAndSettle();
        expect(identical(tester.element(roller), before), isTrue);
        expect(inBar(find.bySemanticsLabel('KD 2.900')), findsOneWidget);
        expect(find.semantics.byLabel('Updating…'), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'the struck total shows only with savings, and never while updating',
      (tester) async {
        Finder struck() => inBar(
          find.byWidgetPredicate(
            (widget) => widget is JameiaMoneyText && widget.strike,
          ),
        );
        useCart(snapshot(lines: const [riceOnSale, oil]));
        await checkoutCubit.start(defaultAddressId: 'a1');
        await pumpBar(tester);

        // 2.600 + 0.600 the rice saves.
        expect(struck(), findsOneWidget);
        expect(tester.widget<JameiaMoneyText>(struck()).kd, 3.2);

        await emit(
          tester,
          snapshot(lines: const [riceOnSale, oil], pending: true),
        );
        await tester.pumpAndSettle();
        expect(struck(), findsNothing);

        await emit(tester, snapshot());
        await tester.pumpAndSettle();
        expect(struck(), findsNothing);
      },
    );

    testWidgets('CT-F2: the total is where products fly while it is open', (
      tester,
    ) async {
      final shell = GlobalKey(debugLabel: 'shell cart');
      FlyToCart.registerTarget(shell);
      await pumpBar(tester);

      final target = FlyToCart.debugTarget;
      expect(target, isNot(shell));
      expect(inBar(find.byKey(target!)), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(target),
          matching: find.byType(CheckoutBarTotal),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      expect(FlyToCart.debugTarget, shell);
    });
  });

  group('fact line', () {
    testWidgets('CT-T2: rotates without rebuilding the bar', (tester) async {
      // Free delivery waives the 0.500 fee: "Saving" and "Free delivery".
      useCart(snapshot(freeDelivery: true));
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);
      expect(find.byType(RotatingLine), findsOneWidget);
      expect(find.text('Saving KD 0.500'), findsOneWidget);

      final probe = RebuildProbe<Widget, Type>((widget) => widget.runtimeType)
        ..start();
      addTearDown(probe.stop);
      await tester.pump(AppMotion.carousel);
      await tester.pump(AppMotion.flip);
      await tester.pump(const Duration(milliseconds: 16));

      expect(probe.of(RotatingLine), greaterThan(0));
      expect(find.text('Free delivery'), findsOneWidget);
      for (final type in const <Type>[
        CheckoutPlaceOrderBar,
        CheckoutBarTotal,
        CheckoutBarLine,
        CheckoutPlaceButton,
      ]) {
        expect(probe.of(type), 0, reason: '$type rebuilt on a rotation');
      }
    });

    testWidgets('holds still while the cart re-prices', (tester) async {
      useCart(snapshot(freeDelivery: true));
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);
      await emit(tester, snapshot(freeDelivery: true, pending: true));

      expect(
        tester.state<RotatingLineState>(find.byType(RotatingLine)).debugResting,
        isFalse,
      );
    });

    /// No swap is under way: a swapping line holds two facts (the one
    /// leaving and the one arriving) for [AppMotion.flip].
    Future<void> expectNoSwap(WidgetTester tester) async {
      final facts = find.descendant(
        of: find.byType(RotatingLine),
        matching: find.byType(CheckoutBarFactText),
      );
      expect(facts, findsOneWidget);
      await tester.pump(AppMotion.flip ~/ 2);
      expect(facts, findsOneWidget);
    }

    testWidgets('the fact on screen stays through a re-price: no swap, and '
        'the saving comes back in place', (tester) async {
      useCart(snapshot(lines: const [riceOnSale, oil], freeDelivery: true));
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);
      // 0.600 off the rice + the 0.500 delivery free delivery waived.
      expect(find.text('Saving KD 1.100'), findsOneWidget);
      final line = tester.state(find.byType(RotatingLine));

      // A tap: the saving leaves the facts while the cart re-prices.
      await emit(
        tester,
        snapshot(
          lines: const [riceOnSale, oil],
          freeDelivery: true,
          pending: true,
        ),
      );
      expect(find.text('Saving KD 1.100'), findsOneWidget);
      expect(find.text('Free delivery'), findsNothing);
      await expectNoSwap(tester);

      // The reply: the saving is back, in place — not news, no slide.
      await emit(
        tester,
        snapshot(lines: const [riceOnSale, oil], freeDelivery: true),
      );
      expect(find.text('Saving KD 1.100'), findsOneWidget);
      expect(find.text('Free delivery'), findsNothing);
      await expectNoSwap(tester);
      // The same line throughout: never torn down and mounted again.
      expect(tester.state(find.byType(RotatingLine)), same(line));
    });

    testWidgets('a saving that is the only fact is held, not re-mounted', (
      tester,
    ) async {
      useCart(snapshot(lines: const [riceOnSale, oil]));
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);
      expect(find.text('Saving KD 0.600'), findsOneWidget);
      final line = tester.state(find.byType(RotatingLine));

      await emit(
        tester,
        snapshot(lines: const [riceOnSale, oil], pending: true),
      );
      expect(find.text('Saving KD 0.600'), findsOneWidget);

      await emit(tester, snapshot(lines: const [riceOnSale, oil]));
      expect(find.text('Saving KD 0.600'), findsOneWidget);
      await expectNoSwap(tester);
      expect(tester.state(find.byType(RotatingLine)), same(line));
    });

    testWidgets('a blocking reason is pinned alone and never rotates', (
      tester,
    ) async {
      useCart(
        snapshot(freeDelivery: true, minOrderFils: 5000, meetsMinOrder: false),
      );
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);

      const reason = 'Add KD 2.900 more to reach the minimum order';
      expect(find.text(reason), findsOneWidget);
      expect(find.byType(RotatingLine), findsNothing);

      await tester.pump(AppMotion.carousel * 2);
      expect(find.text(reason), findsOneWidget);
      expect(find.text('Free delivery'), findsNothing);
    });

    testWidgets('the coupon and the gap facts name their amounts', (
      tester,
    ) async {
      useCart(
        snapshot(
          coupon: const CartCouponEntity(code: 'SAVE', discountFils: 200),
          couponDiscountFils: 200,
        ),
      );
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);

      // Every saving together first, then the coupon's own.
      expect(find.text('Saving KD 0.200'), findsOneWidget);
      await tester.pump(AppMotion.carousel);
      await tester.pump(AppMotion.flip);
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('KD 0.200 saved with SAVE'), findsOneWidget);
    });
  });

  group('place order', () {
    testWidgets('a disabled tap with no reason fires no haptic and no snack', (
      tester,
    ) async {
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);
      await emit(tester, snapshot(pending: true));
      final haptics = recordHaptics(tester);

      await tapPlaceOrder(tester);

      expect(haptics, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(checkoutRepository.calls, isNot(contains('place:cod')));
    });

    testWidgets('offline: the tap says the changes must reach the server', (
      tester,
    ) async {
      useCart(snapshot(unsynced: true));
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);
      final haptics = recordHaptics(tester);

      await tapPlaceOrder(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(haptics, hasLength(1));
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Changes must reach the server before checkout'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a line issue asks for the items sheet', (tester) async {
      useCart(
        snapshot(
          lines: const [
            CartLineEntity(
              key: 'l1',
              product: testProduct,
              quantity: 2,
              unitPriceFils: 600,
              lineTotalFils: 1200,
              issue: CartLineIssue.outOfStock,
            ),
            oil,
          ],
        ),
      );
      await checkoutCubit.start(defaultAddressId: 'a1');
      final ui = await pumpBar(tester);

      await tapPlaceOrder(tester);

      expect(ui.itemsRequests.value, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('no destination: the tap signals the destination row', (
      tester,
    ) async {
      final ui = await pumpBar(tester);
      final haptics = recordHaptics(tester);

      await tapPlaceOrder(tester);

      expect(ui.blocked.value?.$1, CheckoutBlockReason.destination);
      expect(haptics, hasLength(1));
    });

    testWidgets('offline: a calm line; the tap checks first and, still '
        'offline, sends nothing', (tester) async {
      await checkoutCubit.start(defaultAddressId: 'a1');
      var checks = 0;
      var nudges = 0;
      await pumpBar(
        tester,
        child: ConnectivityScope(
          isOffline: true,
          reconnectEpoch: 0,
          onNudge: () => nudges++,
          onCheckNow: () async {
            checks++;
            return false;
          },
          child: const CheckoutPlaceOrderBar(),
        ),
      );

      expect(inBar(find.text("You're offline")), findsOneWidget);

      await tapPlaceOrder(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(checks, 1);
      expect(nudges, 1);
      expect(checkoutRepository.calls, isNot(contains('place:cod')));
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(
            "You're offline. Your changes are kept, try again when you're "
            'back.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('offline, but the live check reaches the server: the order '
        'goes', (tester) async {
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(
        tester,
        child: ConnectivityScope(
          isOffline: true,
          reconnectEpoch: 0,
          onNudge: () {},
          onCheckNow: () async => true,
          child: const CheckoutPlaceOrderBar(),
        ),
      );

      await tapPlaceOrder(tester);
      await tester.pumpAndSettle();

      expect(checkoutRepository.calls.where((c) => c.startsWith('place:')), [
        'place:cod',
      ]);
    });

    testWidgets('an open order places once, with the cart facts', (
      tester,
    ) async {
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester);

      await tapPlaceOrder(tester);
      await tester.pumpAndSettle();

      expect(checkoutRepository.calls.where((c) => c.startsWith('place:')), [
        'place:cod',
      ]);
      expect(checkoutCubit.state.status, CheckoutStatus.placed);
    });
  });

  group('hint', () {
    testWidgets(
      'CT-H1: the hint shows the top saving and rests after its float',
      (tester) async {
        useCart(snapshot(lines: const [riceOnSale, oil]));
        await checkoutCubit.start(defaultAddressId: 'a1');
        await pumpBar(tester, child: const _BarWithHint());

        expect(find.byType(CheckoutHintBubble), findsOneWidget);
        expect(find.text('KD 0.600 off'), findsNothing); // one rich text
        expect(
          find.textContaining('KD 0.600 off these 2 items', findRichText: true),
          findsOneWidget,
        );
        expect(find.byType(FloatLoop), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('no line on sale → no hint', (tester) async {
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester, child: const _BarWithHint());

      expect(find.byType(CheckoutHintBubble), findsNothing);
    });

    testWidgets('CT-H2 (tap): a tap dismisses it for good', (tester) async {
      useCart(snapshot(lines: const [riceOnSale, oil]));
      await checkoutCubit.start(defaultAddressId: 'a1');
      final ui = await pumpBar(tester, child: const _BarWithHint());

      await tester.tap(find.byType(CheckoutHintBubble));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutHintBubble), findsNothing);
      expect(ui.hintDismissed.value, isTrue);

      // A re-price later does not bring it back.
      await emit(
        tester,
        snapshot(lines: [riceOnSale.withQuantity(3), oil], subtotalFils: 2700),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutHintBubble), findsNothing);
    });

    testWidgets('CT-H3: placing removes the hint and stops the line', (
      tester,
    ) async {
      useCart(snapshot(lines: const [riceOnSale, oil], freeDelivery: true));
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester, child: const _BarWithHint());
      expect(find.byType(CheckoutHintBubble), findsOneWidget);
      expect(
        tester.state<RotatingLineState>(find.byType(RotatingLine)).debugResting,
        isTrue,
      );

      await tapPlaceOrder(tester);
      await tester.pumpAndSettle();

      expect(checkoutCubit.state.status, CheckoutStatus.placed);
      expect(find.byType(CheckoutHintBubble), findsNothing);
      expect(
        tester.state<RotatingLineState>(find.byType(RotatingLine)).debugResting,
        isFalse,
      );
    });

    for (final locale in const [checkoutEn, checkoutAr]) {
      testWidgets(
        'fits 360 × 800 at 1.3× text (${locale.languageCode}): bar + hint',
        (tester) async {
          useCart(
            snapshot(
              lines: const [riceOnSale, oil],
              freeDelivery: true,
              coupon: const CartCouponEntity(
                code: 'WELCOME10',
                discountFils: 200,
              ),
              couponDiscountFils: 200,
            ),
          );
          await checkoutCubit.start(defaultAddressId: 'a1');
          await pumpBar(
            tester,
            child: const _BarWithHint(),
            locale: locale,
            size: const Size(360, 800),
            textScale: 1.3,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(CheckoutHintBubble), findsOneWidget);

          // Every fact of the line takes its turn without overflowing.
          for (var turn = 0; turn < 4; turn++) {
            await tester.pump(AppMotion.carousel);
            await tester.pump(AppMotion.flip);
            await tester.pump(const Duration(milliseconds: 16));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  });

  group('title bar', () {
    testWidgets('shows the store and the serving branch once both are known', (
      tester,
    ) async {
      await pumpBar(tester, child: const CheckoutTitleBar());
      expect(find.text('Checkout'), findsOneWidget);
      expect(find.text('Jm3eia · Salmiya'), findsNothing);

      await checkoutCubit.start(defaultAddressId: 'a1');
      await tester.pumpAndSettle();
      expect(find.text('Jm3eia · Salmiya'), findsOneWidget);
    });

    testWidgets('shows only what is known', (tester) async {
      checkoutRepository.rulesFailure = const ServerFailure('init down');
      await checkoutCubit.start(defaultAddressId: 'a1');
      await pumpBar(tester, child: const CheckoutTitleBar());

      expect(find.text('Salmiya'), findsOneWidget);
    });
  });
}
