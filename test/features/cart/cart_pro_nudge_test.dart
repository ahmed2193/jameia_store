// Hero Pro on the cart's delivery row, keyed on the app-global Pro status:
// a customer without Pro who pays a delivery fee is told the real amount Pro
// would save (and the nudge opens the Pro page); a member's free delivery
// carries the "pro" tag and is never nudged; an unknown standing shows
// neither; a fee that goes away takes the nudge with it.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/pages/cart_tab_page.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_pro_nudge.dart';
import 'package:hero_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../store_mode/pro_status_fakes.dart';
import 'cart_page_harness.dart';
import 'cart_test_fixtures.dart';
import 'fake_cart_repository.dart';

const AuthCustomerEntity _customer = AuthCustomerEntity(
  id: 'c1',
  phone: '+96550001122',
);

const CartLineEntity _line = CartLineEntity(
  key: 'l1',
  product: testProduct,
  quantity: 2,
  unitPriceFils: 1500,
  lineTotalFils: 3000,
);

CartSnapshot _snapshot({
  int deliveryFeeFils = 750,
  bool freeDelivery = false,
  int revision = 1,
}) => CartSnapshot(
  cart: CartEntity(
    itemCount: 2,
    lines: const <CartLineEntity>[_line],
    totals: CartTotalsEntity(
      subtotalFils: 3000,
      deliveryFeeFils: deliveryFeeFils,
      freeDelivery: freeDelivery,
      baseDeliveryFeeFils: 750,
      totalFils: 3000 + deliveryFeeFils,
    ),
  ),
  isRestored: true,
  revision: revision,
);

void main() {
  late FakeCartRepository repository;
  late CartCubit cartCubit;
  late AuthSessionCubit session;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    session = buildGuestSession();
    repository = FakeCartRepository();
    cartCubit = buildCartCubit(repository);
  });

  tearDown(() async {
    await session.close();
    await cartCubit.close();
    await repository.dispose();
  });

  /// The Cart tab as the router's home (the nudge pushes the Pro page) on
  /// a tall phone, so the summary card is laid out.
  Future<void> pump(
    WidgetTester tester,
    ProStatusCubit status,
    CartSnapshot snapshot,
  ) async {
    tester.view.physicalSize = const Size(430, 2400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => CartTabPage(onBrowse: () {})),
        GoRoute(
          path: Routes.proMembership,
          builder: (_, _) => const Scaffold(body: Text('route:pro')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await pumpCartHost(
      tester,
      repository: repository,
      cart: cartCubit,
      session: session,
      snapshot: snapshot,
      proStatus: status,
      router: router,
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> teardownApp(WidgetTester tester, ProStatusCubit status) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await status.close();
  }

  testWidgets('no Pro yet, a fee to pay: the real saving; tap opens Pro', (
    tester,
  ) async {
    final status = await settledProStatus();
    await pump(tester, status, _snapshot());

    expect(
      find.text('Save KD 0.750 on delivery with Hero Pro'),
      findsOneWidget,
    );
    expect(find.text('Join'), findsOneWidget);

    await tester.tap(find.byType(CartProNudge));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('route:pro'), findsOneWidget);

    await teardownApp(tester, status);
  });

  testWidgets('member: free delivery with the "pro" tag, never a nudge', (
    tester,
  ) async {
    final status = await settledProStatus(
      customer: _customer,
      subscription: ProSubscription(
        id: 's1',
        planId: 'monthly',
        status: ProSubscriptionStatus.active,
        currentPeriodEnd: DateTime(2026, 10, 17, 12),
      ),
    );
    await pump(tester, status, _snapshot(deliveryFeeFils: 0, freeDelivery: true));

    expect(find.text('pro'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.bySemanticsLabel('Free delivery with Hero Pro'), findsOne);
    expect(find.textContaining('on delivery with Hero Pro'), findsNothing);

    await teardownApp(tester, status);
  });

  testWidgets('unknown standing: neither the nudge nor the tag', (
    tester,
  ) async {
    final status = buildProStatus();
    await pump(tester, status, _snapshot());

    expect(find.textContaining('on delivery with Hero Pro'), findsNothing);
    expect(find.text('pro'), findsNothing);

    await teardownApp(tester, status);
  });

  testWidgets('the fee goes (an offer made delivery free): so does the nudge', (
    tester,
  ) async {
    final status = await settledProStatus(customer: _customer);
    await pump(tester, status, _snapshot());
    expect(
      find.text('Save KD 0.750 on delivery with Hero Pro'),
      findsOneWidget,
    );

    await emitCartSnapshot(
      tester,
      repository,
      _snapshot(deliveryFeeFils: 0, freeDelivery: true, revision: 2),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('on delivery with Hero Pro'), findsNothing);
    // Free thanks to the offer, not to Pro: no tag either.
    expect(find.text('pro'), findsNothing);

    await teardownApp(tester, status);
  });
}
