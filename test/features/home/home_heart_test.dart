// The warm touches of the home tab: a hello for the hour that waves, loops
// that rest between bursts without drawing, a long press that opens a quick
// look at a product, and confetti for the first thing into an empty basket.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/config/theme/app_spacing.dart';
import 'package:hero_mart/src/core/motion/confetti_burst.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/catalog_product_card.dart';
import 'package:hero_mart/src/core/widgets/shelf_add_button.dart';
import 'package:hero_mart/src/core/widgets/shelf_tag_pill.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/entities/cart_snapshot.dart';
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
import 'package:hero_mart/src/features/home/domain/entities/home_greeting.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_confetti.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_greeting_strip.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_loop.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_product_rail.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_product_tile.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_quick_look_sheet.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_waving_hand.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import '../cart/fake_cart_repository.dart';

const double _tileWidth = 120;

const CatalogProductEntity _rice = CatalogProductEntity(
  id: 'p1',
  slug: 'basmati-rice',
  name: 'Basmati rice',
  priceFils: 1000,
  stock: 12,
);

const CatalogProductEntity _bestSellerRice = CatalogProductEntity(
  id: 'p2',
  slug: 'jasmine-rice',
  name: 'Jasmine rice',
  priceFils: 1200,
  stock: 12,
  tags: ['best-seller'],
);

const AuthCustomerEntity _sara = AuthCustomerEntity(
  id: 'c1',
  phone: '+96550001122',
  nameEn: 'Sara Ali',
);

DateTime _at(int hour, [int minute = 0]) => DateTime(2026, 9, 25, hour, minute);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthSessionCubit session;
  late List<Object?> haptics;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() {
    session = AuthSessionCubit(
      restoreSession: FakeRestoreSessionUseCase(const Right(null)),
      logout: FakeLogoutUseCase(),
      watchExpiry: FakeWatchSessionExpiryUseCase(),
      getCachedCustomer: FakeGetCachedCustomerUseCase(),
      saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
      clearCachedCustomer: FakeClearCachedCustomerUseCase(),
    );
    haptics = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await session.close();
  });

  Widget app(Widget child, {bool reducedMotion = false}) =>
      BlocProvider<AuthSessionCubit>.value(
        value: session,
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reducedMotion),
              child: Scaffold(body: child),
            ),
          ),
        ),
      );

  group('HomeGreeting', () {
    test('reads the part of the day from the hour', () {
      expect(HomeGreeting.dayPartOf(_at(5)), HomeDayPart.morning);
      expect(HomeGreeting.dayPartOf(_at(11, 59)), HomeDayPart.morning);
      expect(HomeGreeting.dayPartOf(_at(12)), HomeDayPart.afternoon);
      expect(HomeGreeting.dayPartOf(_at(16, 59)), HomeDayPart.afternoon);
      expect(HomeGreeting.dayPartOf(_at(17)), HomeDayPart.evening);
      expect(HomeGreeting.dayPartOf(_at(20, 59)), HomeDayPart.evening);
      expect(HomeGreeting.dayPartOf(_at(21)), HomeDayPart.night);
      expect(HomeGreeting.dayPartOf(_at(0)), HomeDayPart.night);
      expect(HomeGreeting.dayPartOf(_at(4, 59)), HomeDayPart.night);
    });

    test('greets by first name, or by the hour alone', () {
      final named = HomeGreeting.at(_at(9), fullName: '  Sara   Ali ');
      expect(named.firstName, 'Sara');
      expect(named.hasName, isTrue);

      final unnamed = HomeGreeting.at(_at(9));
      expect(unnamed.hasName, isFalse);
      expect(unnamed, const HomeGreeting(dayPart: HomeDayPart.morning));
    });
  });

  group('HomeGreetingStrip', () {
    double swingOf(WidgetTester tester) => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(HomeWavingHand),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .entry(1, 0);

    testWidgets('says good morning to the customer by first name', (
      tester,
    ) async {
      session.signedIn(_sara);
      await tester.pumpWidget(app(HomeGreetingStrip(clock: () => _at(8))));

      expect(find.text('Good morning, Sara'), findsOneWidget);
      expect(find.text('Start your day with something fresh'), findsOneWidget);
    });

    testWidgets('signed out, it greets by the hour alone', (tester) async {
      await tester.pumpWidget(app(HomeGreetingStrip(clock: () => _at(22))));

      expect(find.text('Good night'), findsOneWidget);
      expect(find.text('Craving a late-night snack?'), findsOneWidget);
    });

    testWidgets('the hand waves hello as it lands, and back on a tap', (
      tester,
    ) async {
      await tester.pumpWidget(app(HomeGreetingStrip(clock: () => _at(15))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(swingOf(tester), isNot(0), reason: 'waves on arrival');

      await tester.pump(const Duration(seconds: 2));
      expect(swingOf(tester), 0, reason: 'then rests');

      await tester.tap(find.byType(HomeGreetingStrip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(swingOf(tester), isNot(0), reason: 'waves back');
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('holds still under reduced motion', (tester) async {
      await tester.pumpWidget(
        app(HomeGreetingStrip(clock: () => _at(9)), reducedMotion: true),
      );
      await tester.pump();
      await tester.tap(find.byType(HomeGreetingStrip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(swingOf(tester), 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  testWidgets('a loop with a rest draws no frame between two bursts', (
    tester,
  ) async {
    const burst = Duration(milliseconds: 200);
    const rest = Duration(seconds: 1);
    await tester.pumpWidget(
      app(
        HomeLoop(
          period: burst,
          rest: rest,
          builder: (context, t, child) =>
              Opacity(opacity: 1 - t / 2, child: child),
          child: const SizedBox.square(dimension: _tileWidth),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'bursting');

    await tester.pump(burst);
    // A controller is done only once a frame lands past its duration.
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester.binding.hasScheduledFrame,
      isFalse,
      reason: 'resting on a timer',
    );

    await tester.pump(rest);
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'the next burst');
  });

  group('HomeProductTile', () {
    late FakeCartRepository cartRepository;
    late CartCubit cart;

    setUp(() => cartRepository = FakeCartRepository());

    tearDown(() async {
      await cart.close();
      await cartRepository.dispose();
    });

    /// The cart is built and started on the real event loop, like the
    /// app-global one (see home_cart_bar_test.dart).
    Future<void> pumpTile(
      WidgetTester tester, {
      ValueChanged<CatalogProductEntity>? onOpen,
      TextDirection textDirection = TextDirection.ltr,
      Widget? child,
    }) async {
      await tester.runAsync(() async {
        cart = CartCubit(
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
        final page = Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: HomeConfetti(
              child:
                  child ??
                  Center(
                    child: HomeProductTile(
                      product: _rice,
                      width: _tileWidth,
                      onOpen: onOpen ?? (_) {},
                    ),
                  ),
            ),
          ),
        );
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthSessionCubit>.value(value: session),
              BlocProvider<CartCubit>.value(value: cart),
            ],
            child: MaterialApp.router(
              routerConfig: GoRouter(
                routes: [GoRoute(path: '/', builder: (_, _) => page)],
              ),
            ),
          ),
        );
        // Lets the cart's first snapshot arrive.
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
    }

    Object? confettiShot(WidgetTester tester) =>
        tester.widget<ConfettiBurst>(find.byType(ConfettiBurst)).playKey;

    void tapAdd(WidgetTester tester) => tester
        .widget<CatalogProductCard>(find.byType(CatalogProductCard))
        .onAdd();

    testWidgets('a long press opens a quick look that leads to the product', (
      tester,
    ) async {
      final opened = <CatalogProductEntity>[];
      await pumpTile(tester, onOpen: opened.add);

      await tester.longPress(find.byType(CatalogProductCard));
      await tester.pumpAndSettle();
      expect(find.byType(HomeQuickLookSheet), findsOneWidget);
      expect(find.text('Add to cart'), findsOneWidget);
      expect(haptics, contains('HapticFeedbackType.lightImpact'));

      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeQuickLookSheet), findsNothing);
      expect(opened, [_rice]);
    });

    Widget rail(HomeRailLayout layout) => SingleChildScrollView(
      child: HomeProductRail(
        section: HomeProductRailSection(
          id: 'rail',
          layout: layout,
          products: const [_rice, _bestSellerRice],
        ),
        onOpenProduct: (_) {},
        onViewAll: () {},
      ),
    );

    testWidgets('the names of a grid row line up, tagged or not', (
      tester,
    ) async {
      await pumpTile(tester, child: rail(HomeRailLayout.grid));

      expect(tester.takeException(), isNull);
      final cards = tester.widgetList<CatalogProductCard>(
        find.byType(CatalogProductCard),
      );
      expect(cards.map((card) => card.reservesTagLine), [true, true]);
      // The untagged card keeps an empty tag line beside the "Best seller".
      expect(find.byType(ShelfTagPill), findsNWidgets(2));
      expect(find.text('Best seller'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(_bestSellerRice.name)).dy,
        tester.getTopLeft(find.text(_rice.name)).dy,
      );
    });

    testWidgets('a one-row strip skips the empty tag line', (tester) async {
      await pumpTile(tester, child: rail(HomeRailLayout.slider));

      expect(tester.takeException(), isNull);
      final cards = tester.widgetList<CatalogProductCard>(
        find.byType(CatalogProductCard),
      );
      expect(cards.map((card) => card.reservesTagLine), [false, false]);
      expect(find.byType(ShelfTagPill), findsOneWidget);
    });

    for (final direction in TextDirection.values) {
      testWidgets('the +1 rises from the round + of the card, $direction', (
        tester,
      ) async {
        await pumpTile(tester, textDirection: direction);
        final plusOne = find.text('+1');
        final add = tester.getRect(find.byType(ShelfAddButton));

        // At rest (and at the start of a burst) the "+1" stands on the
        // button, centred over it.
        void standsOnTheButton() {
          final rect = tester.getRect(plusOne);
          final pill = tester.getRect(
            find.ancestor(of: plusOne, matching: find.byType(Container)).first,
          );
          expect(rect.center.dx, closeTo(add.center.dx, 0.5));
          expect(pill.bottom, closeTo(add.top + AppSpacing.s4, 0.5));
        }

        standsOnTheButton();
        tapAdd(tester);
        await tester.pump();
        standsOnTheButton();

        // Then it rises away from the button.
        await tester.pump(AppMotion.drawOn ~/ 2);
        expect(tester.getRect(plusOne).bottom, lessThan(add.top));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('the first thing into an empty basket bursts into confetti', (
      tester,
    ) async {
      await pumpTile(tester);
      expect(confettiShot(tester), isNull);

      tapAdd(tester);
      await tester.pump();
      expect(confettiShot(tester), 1);
      expect(haptics, contains('HapticFeedbackType.mediumImpact'));
      expect(cartRepository.calls, isNotEmpty);
      await tester.pumpAndSettle();
    });

    testWidgets('a basket that already has things gets no confetti', (
      tester,
    ) async {
      cartRepository.snapshot = const CartSnapshot(
        cart: CartEntity(
          itemCount: 1,
          lines: [
            CartLineEntity(
              key: 'l1',
              product: _rice,
              quantity: 1,
              unitPriceFils: 1000,
              lineTotalFils: 1000,
            ),
          ],
        ),
        isRestored: true,
      );
      await pumpTile(tester);

      tapAdd(tester);
      await tester.pump();
      expect(confettiShot(tester), isNull);
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
      await tester.pumpAndSettle();
    });
  });
}
