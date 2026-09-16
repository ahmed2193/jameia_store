// Smoke tests for the rebuilt KeeMart product-detail page (PDP).
//
// Boots the real service locator (loads the bundled jm3eia catalog), mounts
// `ProductDetailScreen` for a real product and verifies:
//   • the page builds with no thrown exception (collapsing app bar + gallery +
//     sections + sticky bar),
//   • the title, "Product details" and the sticky "Add to cart" render,
//   • tapping "Add to cart" adds the product to the unified cart.
//
// Network thumbnails (KeetaImage) resolve to placeholders under test — expected
// and must not throw.

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

import 'package:jameia_mart/core/config/service_locator.dart';
import 'package:jameia_mart/core/data/keeta_repository.dart';
import 'package:jameia_mart/core/data/models/models.dart';
import 'package:jameia_mart/core/storage/storage_injection.dart';
import 'package:jameia_mart/core/theme/app_theme.dart';
import 'package:jameia_mart/features/cart/cart_injection_container.dart';
import 'package:jameia_mart/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/features/product_details/product_details_injection_container.dart';
import 'package:jameia_mart/features/product_details/presentation/screens/product_detail_screen.dart';
import 'package:jameia_mart/features/store_mode/presentation/cubit/store_mode_cubit.dart';
import 'package:jameia_mart/features/store_mode/store_mode_injection_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeetaRepository repo;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await setupServiceLocator();
    await initCoreStorage();
    await initCartFeature();
    initStoreModeFeature();
    initProductDetailsFeature();
    repo = sl<KeetaRepository>();

    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  Future<void> pumpPdp(
      WidgetTester tester, Product product, CartCubit cubit) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cubit),
          // The refactored PDP has a BlocListener/BlocBuilder<StoreModeCubit>
          // (VIP ⇄ Mart), so the screen needs the global store-mode cubit above
          // it — mirrors main.dart's root MultiBlocProvider.
          BlocProvider<StoreModeCubit>(create: (_) => sl<StoreModeCubit>()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: ProductDetailScreen(product: product),
        ),
      ),
    );
    // Bounded pumps (network image timers never quiesce → no pumpAndSettle).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('PDP builds + renders title / details / sticky Add-to-cart',
      (tester) async {
    final product = repo.allProducts.firstWhere(
      (p) => !p.hasVariants && p.available,
      orElse: () => repo.allProducts.first,
    );
    final cubit = CartCubit();
    addTearDown(cubit.close);

    await pumpPdp(tester, product, cubit);

    expect(tester.takeException(), isNull);
    // Title shows (page body + possibly the collapsed app bar).
    expect(find.text(product.displayName), findsWidgets);
    // Sticky CTA is always mounted (bottom bar).
    expect(find.text('Add to cart'), findsOneWidget);

    // Scroll down to build the deeper section slivers (beyond the cache extent),
    // then assert the always-present spec card header renders.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('Product details'), findsWidgets);

    // Dispose the tree so the coupon-countdown timer is cancelled before the
    // test body returns (avoids a pending-timer failure).
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sticky Add-to-cart adds the product to the cart', (tester) async {
    final product = repo.allProducts.firstWhere(
      (p) => !p.hasVariants && p.available,
      orElse: () => repo.allProducts.first,
    );
    final cubit = CartCubit();
    addTearDown(cubit.close);

    await pumpPdp(tester, product, cubit);
    expect(cubit.state.totalQty, 0);

    await tester.tap(find.text('Add to cart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(cubit.state.totalQty, greaterThan(0));

    await tester.pumpWidget(const SizedBox());
  });
}
