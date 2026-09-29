// What one cart tap costs on screen: a quantity change rebuilds its own row
// only (never the list, never the other rows), a reply that only moves an
// offer's progress rebuilds the bar and never the page or the lines, a
// removal keeps the rows below it, a snapshot that only flips the sync flags
// rebuilds nothing at all, the bar total stays mounted so it can roll, a
// hidden Cart tab (the shell keeps it mounted off screen) runs no animation
// at all and showing or hiding it rebuilds no list, and typing or the
// keyboard never rebuilds the coupon sheet.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_ref.dart';
import 'package:hero_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:hero_mart/src/core/motion/rolling_number.dart';
import 'package:hero_mart/src/core/widgets/hero_bar_total.dart';
import 'package:hero_mart/src/core/widgets/hero_bottom_bar.dart';
import 'package:hero_mart/src/core/widgets/hero_sheet_header.dart';
import 'package:hero_mart/src/core/widgets/hero_submit_button.dart';
import 'package:hero_mart/src/core/widgets/keyboard_inset_padding.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/pages/cart_tab_page.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_body.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_checkout_bar.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_coupon_sheet.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_line_tile.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_lines_sliver.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_totals_summary.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/deals/cart_deal_track.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import 'cart_page_harness.dart';
import 'cart_test_fixtures.dart';
import 'fake_cart_repository.dart';

const CatalogProductEntity _thirdProduct = CatalogProductEntity(
  id: 'p3',
  slug: 'green-tea',
  name: 'Green tea',
  priceFils: 900,
);

const CartLineEntity _a = CartLineEntity(
  key: 'la',
  product: testProduct,
  quantity: 1,
  unitPriceFils: 1500,
  lineTotalFils: 1500,
);
const CartLineEntity _b = CartLineEntity(
  key: 'lb',
  product: otherProduct,
  quantity: 1,
  unitPriceFils: 2500,
  lineTotalFils: 2500,
);
const CartLineEntity _c = CartLineEntity(
  key: 'lc',
  product: _thirdProduct,
  quantity: 1,
  unitPriceFils: 900,
  lineTotalFils: 900,
);

/// A free-delivery offer counting the subtotal, [currentFils] of 10 KD in.
CartOfferProgressEntity _freeDeliveryAt(int currentFils) =>
    CartOfferProgressEntity(
      offerId: 'o1',
      name: 'Free delivery',
      kind: OfferProgressKind.subtotal,
      currentValue: currentFils,
      targetValue: 10000,
      remainingValue: 10000 - currentFils,
      reward: const OfferRewardEntity(type: OfferRewardType.freeDelivery),
    );

CartSnapshot _snapshot(
  List<CartLineEntity> lines, {
  required int revision,
  bool pending = false,
  bool syncing = false,
  int totalFils = 3000,
  List<CartOfferProgressEntity> progress = const <CartOfferProgressEntity>[],
}) => CartSnapshot(
  cart: CartEntity(
    itemCount: lines.fold<int>(0, (sum, line) => sum + line.quantity),
    // A fresh list on every snapshot, as the repository's projection does.
    lines: List<CartLineEntity>.of(lines),
    offerProgress: List<CartOfferProgressEntity>.of(progress),
    totals: CartTotalsEntity(totalFils: totalFils),
  ),
  isRestored: true,
  hasPendingChanges: pending,
  isSyncing: syncing,
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

  Future<void> pumpHome(
    WidgetTester tester,
    CartSnapshot snapshot,
    Widget home,
  ) => pumpCartHost(
    tester,
    repository: repository,
    cart: cartCubit,
    session: session,
    snapshot: snapshot,
    home: home,
  );

  Future<void> pump(
    WidgetTester tester,
    CartSnapshot snapshot, {
    bool hidden = false,
  }) {
    final page = CartTabPage(onBrowse: () {});
    return pumpHome(
      tester,
      snapshot,
      // The shell keeps the Cart tab in an IndexedStack slot.
      hidden
          ? IndexedStack(index: 1, children: [page, const SizedBox.shrink()])
          : page,
    );
  }

  Future<void> emit(WidgetTester tester, CartSnapshot snapshot) =>
      emitCartSnapshot(tester, repository, snapshot);

  testWidgets('T1: a tap on one line rebuilds that row once, never another', (
    tester,
  ) async {
    await pump(tester, _snapshot(const [_a, _b], revision: 1));
    final rows = RebuildProbe<CartLineTile, CartLineRef>((w) => w.lineRef)
      ..start();
    addTearDown(rows.stop);

    // E1 projection: a new list, A changed, B the same instance.
    await emit(
      tester,
      _snapshot([_a.withQuantity(2), _b], revision: 2, pending: true),
    );
    // E2 request in flight: a new list, same content.
    await emit(
      tester,
      _snapshot(
        [_a.withQuantity(2), _b],
        revision: 3,
        pending: true,
        syncing: true,
      ),
    );
    // E4 server reply: fresh instances, equal by value.
    await emit(
      tester,
      _snapshot([_a.withQuantity(2), _b.withQuantity(1)], revision: 4),
    );

    expect(rows.of(_b.ref), 0);
    expect(rows.of(_a.ref), 1);
  });

  testWidgets(
    'T1c: a reply that moves an offer\'s progress rebuilds the bar, never '
    'the page or the lines',
    (tester) async {
      await pump(
        tester,
        _snapshot(
          const [_a, _b],
          revision: 1,
          progress: [_freeDeliveryAt(4000)],
        ),
      );
      final probe = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
      addTearDown(probe.stop);

      // E1 projection: A goes to 2, the progress is the device's copy.
      await emit(
        tester,
        _snapshot(
          [_a.withQuantity(2), _b],
          revision: 2,
          pending: true,
          progress: [_freeDeliveryAt(4000)],
        ),
      );
      // E4 server reply: the subtotal moved, so the remaining amount did.
      await emit(
        tester,
        _snapshot(
          [_a.withQuantity(2), _b],
          revision: 3,
          progress: [_freeDeliveryAt(5500)],
        ),
      );

      // Only the deals strip follows the progress: its track, once.
      expect(probe.of(CartDealTrack), 1);
      expect(probe.of(CartBody), 0);
      expect(probe.of(CartLinesSliver), 0);
      expect(probe.of(CartLineTile), 1); // A at E1, nothing else
    },
  );

  testWidgets('T1b: removing a line keeps the rows below it', (tester) async {
    await pump(tester, _snapshot(const [_a, _b, _c], revision: 1));
    final before = tester.element(
      find.byKey(const ValueKey(CartLineRef('p3'))),
    );
    final rows = RebuildProbe<CartLineTile, CartLineRef>((w) => w.lineRef)
      ..start();
    addTearDown(rows.stop);

    await emit(tester, _snapshot(const [_b, _c], revision: 2));
    await tester.pump(const Duration(milliseconds: 400)); // the fold
    await tester.pump(); // the list drops the folded slot

    final after = tester.element(find.byKey(const ValueKey(CartLineRef('p3'))));
    expect(identical(before, after), isTrue);
    expect(rows.of(_c.ref), lessThanOrEqualTo(1));
    expect(find.text('Basmati rice'), findsNothing);
  });

  testWidgets(
    'T2: a snapshot that only flips the sync flags rebuilds nothing',
    (tester) async {
      await pump(
        tester,
        _snapshot([_a.withQuantity(2), _b], revision: 1, pending: true),
      );
      // Keyed by type name: the provider scope that hands each emission to
      // the selects is private, and it is the one thing allowed to rebuild.
      final probe = RebuildProbe<Widget, String>(
        (w) => w.runtimeType.toString(),
      )..start();
      addTearDown(probe.stop);

      await emit(
        tester,
        _snapshot(
          [_a.withQuantity(2), _b],
          revision: 2,
          pending: true,
          syncing: true,
        ),
      );
      await emit(
        tester,
        _snapshot([_a.withQuantity(2), _b], revision: 3, pending: true),
      );

      expect(probe.of('$CartTotalsSummary'), 0);
      expect(probe.of('$CartCheckoutBar'), 0);
      expect(probe.of('$HeroBottomBar'), 0);
      expect(probe.of('$HeroBarTotal'), 0);
      expect(probe.of('$CartLinesSliver'), 0);
      expect(probe.of('$CartLineTile'), 0);
      // Nothing else either: only the provider's own scope ran, once per
      // emission, to check the selects.
      final plumbing = probe.of('_InheritedProviderScope<CartCubit?>');
      expect(plumbing, 2);
      expect(probe.total - plumbing, 0);
    },
  );

  testWidgets('T3: the bar total is never re-created, so it rolls', (
    tester,
  ) async {
    await pump(tester, _snapshot(const [_a, _b], revision: 1));
    final bar = find.descendant(
      of: find.descendant(
        of: find.byType(CartCheckoutBar),
        matching: find.byType(HeroBarTotal),
      ),
      matching: find.byType(RollingNumber),
    );
    final before = tester.element(bar);

    // E1: pending — the bar says "Updating…" over the held amount.
    await emit(
      tester,
      _snapshot([_a.withQuantity(2), _b], revision: 2, pending: true),
    );
    // E4: the server's new total.
    await emit(
      tester,
      _snapshot([_a.withQuantity(2), _b], revision: 3, totalFils: 4500),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(identical(tester.element(bar), before), isTrue);
    final semantics = tester.ensureSemantics();
    expect(
      find.descendant(
        of: find.byType(CartCheckoutBar),
        matching: find.bySemanticsLabel('KD 4.500'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('T6: a hidden Cart tab ticks nothing on a quantity change', (
    tester,
  ) async {
    await pump(tester, _snapshot(const [_a, _b], revision: 1), hidden: true);

    await emit(
      tester,
      _snapshot([_a.withQuantity(2), _b], revision: 2, pending: true),
    );

    expect(SchedulerBinding.instance.transientCallbackCount, 0);
  });

  testWidgets(
    'T6b: a hidden Cart tab lands removals and inserts at once, no ghost',
    (tester) async {
      await pump(tester, _snapshot(const [_a, _b], revision: 1), hidden: true);

      await emit(tester, _snapshot(const [_a], revision: 2));
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      await tester.pump(); // the list drops the removed slot
      expect(find.text('Olive oil', skipOffstage: false), findsNothing);

      await emit(tester, _snapshot(const [_a, _c], revision: 3));
      expect(SchedulerBinding.instance.transientCallbackCount, 0);
      expect(find.text('Green tea', skipOffstage: false), findsOneWidget);
    },
  );

  testWidgets('T6c: showing or hiding the Cart tab rebuilds no list', (
    tester,
  ) async {
    final tab = ValueNotifier<int>(0);
    addTearDown(tab.dispose);
    final page = CartTabPage(onBrowse: () {});
    await pumpHome(
      tester,
      _snapshot(const [_a, _b], revision: 1),
      ValueListenableBuilder<int>(
        valueListenable: tab,
        builder: (_, index, _) => IndexedStack(
          index: index,
          children: [page, const SizedBox.shrink()],
        ),
      ),
    );
    // A removal replays on the list (which reads the ticker mode then).
    await emit(tester, _snapshot(const [_a], revision: 2));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    final probe = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
    addTearDown(probe.stop);

    tab.value = 1; // hide
    await tester.pump();
    tab.value = 0; // show
    await tester.pump();

    expect(probe.of(CartLinesSliver), 0);
    expect(probe.of(CartBody), 0);
    expect(probe.of(CartLineTile), 0);
  });

  testWidgets(
    'R32: typing and the keyboard rebuild neither the coupon sheet nor its '
    'header or button',
    (tester) async {
      addTearDown(tester.view.reset);
      await pumpHome(
        tester,
        _snapshot(const [_a], revision: 1),
        const Material(
          child: Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: CartCouponSheet(),
          ),
        ),
      );
      final probe = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
      addTearDown(probe.stop);

      await tester.enterText(find.byType(TextField), 'SAVE10');
      await tester.pump();
      // The keyboard slides in: the inset changes under the sheet.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();

      expect(probe.of(KeyboardInsetPadding), greaterThan(0));
      expect(probe.of(CartCouponSheet), 0);
      expect(probe.of(HeroSheetHeader), 0);
      expect(probe.of(HeroSubmitButton), 0);
    },
  );
}
