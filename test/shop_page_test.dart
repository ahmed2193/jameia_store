// Smoke tests for the rebuilt shop menu (jm3eia data-flow + Jameia UI).
//
// Boots the real service locator (loads the bundled jm3eia catalog), then mounts
// `ShopPage` and verifies the new scroll architecture:
//   • the screen builds with no thrown exception — a SINGLE `CustomScrollView`
//     with a pinned collapsing hero + pinned sub-tab bar + pinned rank rail +
//     keyed section slivers (no `ScrollablePositionedList` any more),
//   • section headers + product rows render, the cart bar reacts on add,
//   • the hero collapses NATIVELY on scroll (the cover is dropped once collapsed),
//   • tapping a rank rail item scrolls the body to that section (scroll-spy),
//   • a multi-sub category swaps its body when another sub-tab is tapped.
//
// Network thumbnails (JameiaImage) resolve to placeholders under test — that is
// expected and must not throw.

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/core/storage/storage_injection.dart';
import 'package:jameia_mart/src/features/cart/cart_injection_container.dart';
import 'package:jameia_mart/src/core/data/jameia/jameia_models.dart';
import 'package:jameia_mart/src/core/data/catalog_constants.dart';
import 'package:jameia_mart/src/core/data/jameia_repository.dart';
import 'package:jameia_mart/src/core/data/models/models.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/shop/presentation/pages/shop_page.dart';
import 'package:jameia_mart/src/features/shop/shop_injection_container.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/store_mode_cubit.dart';
import 'package:jameia_mart/src/features/store_mode/store_mode_injection_container.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/rank_rail.dart';
import 'package:jameia_mart/src/features/shop/presentation/widgets/shop_hero.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late JameiaRepository repo;

  setUpAll(() async {
    // Mirror the app boot: DI root + cart feature (so the no-arg CartCubit()
    // factory can resolve its use cases from `sl`).
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await setupServiceLocator();
    await initCoreStorage();
    await initCartFeature();
    initStoreModeFeature();
    initShopFeature();
    repo = sl<JameiaRepository>();

    // Pre-load the English translations into easy_localization's global
    // singleton so widgets' `.tr()` resolve to real text (not raw keys) without
    // wrapping the pump in the async EasyLocalization widget — which would show
    // its loading placeholder and never settle under bounded pumps.
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  Future<void> pumpShop(
    WidgetTester tester,
    String shopId,
    CartCubit cubit,
  ) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cubit),
          // Shop rows read the global store mode (VIP ⇄ Mart) via
          // BlocBuilder<StoreModeCubit>, so provide it above the screen.
          BlocProvider<StoreModeCubit>(create: (_) => sl<StoreModeCubit>()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ShopPage(shopId: shopId),
        ),
      ),
    );
    // Don't pumpAndSettle: the rail's elastic spring + network image timers
    // never quiesce. A few bounded pumps are enough to lay everything out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('catalog produced parent shops with an IMAGE rank rail', (
    tester,
  ) async {
    expect(repo.shops, isNotEmpty);
    // A real "parent" shop = subcategory ranks, each with a picture → the
    // image rail. Asserting image-bearing sections (not just any 2-section
    // leaf Popular/All-items shop) guards against the parent-build regressing.
    final withImageRail = repo.shops
        .where(
          (s) =>
              s.sections.length > 1 &&
              s.sections.any((sec) => sec.image.isNotEmpty),
        )
        .toList();
    expect(
      withImageRail,
      isNotEmpty,
      reason: 'expected parent categories rebuilt as image-rail rank shops',
    );
  });

  testWidgets(
    'ShopPage builds a ranked shop with no exception + renders content',
    (tester) async {
      final shop = repo.shops.firstWhere(
        (s) =>
            s.sections.length > 1 &&
            s.sections.any((sec) => sec.image.isNotEmpty) &&
            s.sections.any((sec) => sec.products.isNotEmpty),
        orElse: () => repo.shops.first,
      );
      final cubit = CartCubit();
      addTearDown(cubit.close);

      await pumpShop(tester, shop.id, cubit);

      expect(tester.takeException(), isNull);

      // First non-empty section's title renders (sits just under the rail).
      final firstSection = shop.sections.firstWhere(
        (sec) => sec.products.isNotEmpty,
      );
      expect(find.text(firstSection.title), findsWidgets);

      // Empty cart → inactive bar shows the min-order pill.
      expect(find.textContaining('Min order'), findsOneWidget);
    },
  );

  testWidgets('cart bar reacts when a no-variant product is added', (
    tester,
  ) async {
    final shop = repo.shops.firstWhere(
      (s) => s.sections.any((sec) => sec.products.any((p) => !p.hasVariants)),
      orElse: () => repo.shops.first,
    );
    final Product plain = shop.sections
        .expand((s) => s.products)
        .firstWhere((p) => !p.hasVariants);

    final cubit = CartCubit();
    addTearDown(cubit.close);

    await pumpShop(tester, shop.id, cubit);

    // Jameia is a single store → the cart is keyed by the unified supplier id,
    // and the cart bar activates only for that id (so it persists across
    // categories). Adding with the category id must NOT activate the bar.
    cubit.add(plain, kJameiaSupplierId);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    // Active bar swaps in → Checkout CTA visible.
    expect(find.text('Checkout'), findsOneWidget);
  });

  // A few bounded pumps to let a programmatic scroll (animateTo + the
  // converge/settle endOfFrame loops) advance without pumpAndSettle (which would
  // hang on the rail spring + image timers).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  ScrollController? scrollControllerOf(WidgetTester tester) =>
      tester.widget<CustomScrollView>(find.byType(CustomScrollView)).controller;

  testWidgets('hero collapses natively on scroll (cover dropped once collapsed)', (
    tester,
  ) async {
    final shop = repo.shops.firstWhere(
      (s) =>
          s.sections.length > 1 &&
          s.sections.any((sec) => sec.products.isNotEmpty),
      orElse: () => repo.shops.first,
    );
    final cubit = CartCubit();
    addTearDown(cubit.close);

    await pumpShop(tester, shop.id, cubit);

    // Expanded: the hero cover is painted.
    expect(find.byType(HeroBg), findsOneWidget);

    // Scroll well past the hero collapse range (cover 150 − bar 48 = 102dp).
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await settle(tester);

    // Collapsed: the pinned hero drops the cover (coverOpacity → 0), leaving the
    // compact chrome bar pinned. This proves the native shrinkOffset collapse,
    // not the old faked-from-scroll-px notifier.
    expect(find.byType(HeroBg), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a rank rail item scrolls the body to that section', (
    tester,
  ) async {
    final shop = repo.shops.firstWhere(
      (s) =>
          s.sections.length >= 3 &&
          s.sections.every((sec) => sec.products.isNotEmpty),
      orElse: () => repo.shops.firstWhere(
        (s) => s.sections.length > 1,
        orElse: () => repo.shops.first,
      ),
    );
    final cubit = CartCubit();
    addTearDown(cubit.close);

    await pumpShop(tester, shop.id, cubit);

    final railItems = find.byType(RankRailItem);
    // Only meaningful when a multi-rank rail is present.
    if (railItems.evaluate().length < 2) return;

    final controller = scrollControllerOf(tester);
    expect(controller, isNotNull);
    expect(controller!.offset, 0); // starts at the top

    // Tap a later rank → the body scrolls down to reveal that section.
    final target = railItems.at(railItems.evaluate().length - 1);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await settle(tester);

    expect(tester.takeException(), isNull);
    // The scroll moved off the top (the section was scrolled under the bars).
    expect(controller.offset, greaterThan(0));
  });

  testWidgets('multi-sub category swaps its body when another sub-tab is tapped', (
    tester,
  ) async {
    // Find a category with more than one sub-category (→ a sub-tab bar shows).
    final multiSub = repo.categories
        .where((JameiaCategory c) => c.subs.length > 1)
        .toList();
    if (multiSub.isEmpty) return; // no multi-sub catalog → nothing to assert
    final cat = multiSub.first;

    final cubit = CartCubit();
    addTearDown(cubit.close);

    // ShopPage takes the CATEGORY id; its subs become the pinned sub-tabs.
    await pumpShop(tester, cat.id, cubit);

    // The sub-tab bar renders a Tab per sub-category.
    final tabs = find.byType(Tab);
    expect(tabs, findsWidgets);

    // Scroll down into the current sub first, so the swap reposition is observable.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await settle(tester);
    final controller = scrollControllerOf(tester);
    expect(controller, isNotNull);
    final beforeSwap = controller!.offset;
    expect(beforeSwap, greaterThan(0)); // we are scrolled down

    // Tapping the second sub-tab swaps the body (jump/swap control, not a
    // TabBarView) AND auto-scrolls so the pinned sub-tab bar docks under the
    // COLLAPSED hero — see ShopPage._swapSub / _subTabDockOffset. It does NOT
    // return to absolute top (the hero stays collapsed), so assert the docked
    // state (hero cover dropped) + that the swap repositioned the scroll.
    await tester.tap(tabs.at(1));
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(
      find.byType(HeroBg),
      findsNothing,
    ); // hero stays collapsed at the dock
    expect(
      controller.offset,
      isNot(beforeSwap),
    ); // swap repositioned the scroll
    expect(find.byType(CustomScrollView), findsOneWidget);
  });
}
