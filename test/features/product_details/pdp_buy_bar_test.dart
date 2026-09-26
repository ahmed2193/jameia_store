// The buy bar's deal tag: the cart offer that counts the product shows over
// the price; none, no tag. "Add to cart" stays one Text in sticker letters.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/core/widgets/sticker_text.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:jameia_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_bottom_bar.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_promo_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdp_test_fakes.dart';

const ProductDetail _eggs = ProductDetail(
  product: CatalogProductEntity(
    id: 'eggs',
    slug: 'fresh-eggs-30',
    name: 'Fresh Eggs (30)',
    priceFils: 2250,
    compareAtFils: 2813,
    stock: 20,
  ),
);

const OfferEntity _dairy = OfferEntity(
  id: 'of-dairy',
  name: '2 KWD off dairy (3 items)',
  triggerType: OfferTriggerType.categoryQuantity,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final raw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(
        withNewProductKeys(json.decode(raw) as Map<String, dynamic>, 'en'),
      ),
    );
  });

  Future<ProductDetailCubit> pump(WidgetTester tester, OfferEntity? offer) async {
    final detail = ProductDetailCubit(
      const StubGetDetail(_eggs),
      StubGetOffer(offer),
      slug: _eggs.product.slug,
    );
    final cart = FakeCartCubit();
    final session = signedOutSession();
    addTearDown(() async {
      await detail.close();
      await cart.close();
      await session.close();
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductDetailCubit>.value(value: detail),
          BlocProvider<CartCubit>.value(value: cart),
          BlocProvider<AuthSessionCubit>.value(value: session),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(), bottomNavigationBar: PdpBottomBar()),
        ),
      ),
    );
    await detail.load();
    await tester.pumpAndSettle();
    return detail;
  }

  testWidgets('the offer that counts the product tags the price', (
    tester,
  ) async {
    await pump(tester, _dairy);

    expect(find.byType(PdpPromoTag), findsOneWidget);
    expect(find.text('2 KWD off dairy (3 items)'), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Add to cart'),
        matching: find.byType(StickerText),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no offer counts it: no tag', (tester) async {
    await pump(tester, null);

    expect(find.byType(PdpPromoTag), findsNothing);
    expect(find.text('Add to cart'), findsOneWidget);
  });
}
