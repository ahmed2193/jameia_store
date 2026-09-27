// The buy bar's price block, Hero style: a deal's "Save N%" over the
// price and the struck price under it, then the Pro line — the Pro price for
// a customer who is not a member, "Pro price" for a member paying it. The
// cart offer that counts the product is a note in the sheet, not the bar.
// "Add to cart" stays one Text in sticker letters.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/widgets/shelf_pro_price_chip.dart';
import 'package:hero_mart/src/core/widgets/shelf_save_badge.dart';
import 'package:hero_mart/src/core/widgets/sticker_text.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:hero_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_bar_price.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_bottom_bar.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_offer_note.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_promo_tag.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdp_test_fakes.dart';

/// On a deal (2.813 → 2.250: 20 % off), no Pro price.
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

/// No deal; members pay 2.000 instead of 2.250.
const ProductDetail _rice = ProductDetail(
  product: CatalogProductEntity(
    id: 'rice',
    slug: 'basmati-rice-5kg',
    name: 'Basmati Rice 5kg',
    priceFils: 2250,
    proPriceFils: 2000,
    stock: 20,
  ),
);

const OfferEntity _dairy = OfferEntity(
  id: 'of-dairy',
  name: '2 KWD off dairy (3 items)',
  triggerType: OfferTriggerType.categoryQuantity,
);

const AuthCustomerEntity _member = AuthCustomerEntity(
  id: '507f1f77bcf86cd799439011',
  phone: '+96512345678',
  isPro: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await speakEnglish();
  });

  /// The sheet's offer note over the buy bar, [served] loaded, for a
  /// customer who is a Pro member when [member].
  Future<void> pump(
    WidgetTester tester, {
    ProductDetail served = _eggs,
    OfferEntity? offer,
    bool member = false,
  }) async {
    final detail = ProductDetailCubit(
      StubWatchDetail(served),
      StubGetOffer(offer),
      slug: served.product.slug,
    );
    final cart = FakeCartCubit();
    final session = signedOutSession();
    if (member) session.signedIn(_member);
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
          home: Scaffold(
            body: Align(
              alignment: AlignmentDirectional.topStart,
              child: PdpOfferNote(),
            ),
            bottomNavigationBar: PdpBottomBar(),
          ),
        ),
      ),
    );
    await detail.load();
    await tester.pumpAndSettle();
  }

  final bar = find.byType(PdpBottomBar);
  Finder inBar(Finder finder) => find.descendant(of: bar, matching: finder);

  group('the cart offer', () {
    testWidgets('shows as a tag in the sheet, not in the bar', (tester) async {
      await pump(tester, offer: _dairy);

      final tag = find.descendant(
        of: find.byType(PdpOfferNote),
        matching: find.byType(PdpPromoTag),
      );
      expect(tag, findsOneWidget);
      expect(find.text('2 KWD off dairy (3 items)'), findsOneWidget);
      expect(inBar(find.byType(PdpPromoTag)), findsNothing);
      expect(
        find.ancestor(
          of: find.text('Add to cart'),
          matching: find.byType(StickerText),
        ),
        findsOneWidget,
      );
    });

    testWidgets('none counts it: no tag, and no room for one', (tester) async {
      await pump(tester);

      expect(find.byType(PdpPromoTag), findsNothing);
      expect(tester.getSize(find.byType(PdpOfferNote)).height, 0);
      expect(find.text('Add to cart'), findsOneWidget);
    });
  });

  group('the price block', () {
    testWidgets('a deal: "Save 20%" over the price, the struck one under it', (
      tester,
    ) async {
      await pump(tester);

      final save = inBar(find.text('Save 20%'));
      expect(save, findsOneWidget);
      expect(inBar(find.byType(ShelfSaveBadge)), findsOneWidget);
      final price = tester.getRect(find.byType(PdpBarPrice));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(price.top));
      expect(inBar(find.text('KD 2.813')), findsOneWidget);
      // No Pro line without a Pro price.
      expect(find.byType(ShelfProPriceChip), findsNothing);
      expect(find.text('Pro price'), findsNothing);
    });

    testWidgets('not a member: what a member would pay, under the price', (
      tester,
    ) async {
      await pump(tester, served: _rice);

      expect(find.byType(ShelfSaveBadge), findsNothing);
      final chip = inBar(find.byType(ShelfProPriceChip));
      expect(chip, findsOneWidget);
      expect(
        find.descendant(of: chip, matching: find.text('KD 2.000')),
        findsOneWidget,
      );
      expect(
        tester.getRect(chip).top,
        greaterThanOrEqualTo(tester.getRect(find.byType(PdpBarPrice)).bottom),
      );
    });

    testWidgets('a member paying the Pro price: "Pro price", the regular '
        'price struck', (tester) async {
      await pump(tester, served: _rice, member: true);

      expect(inBar(find.text('Pro price')), findsOneWidget);
      expect(find.byType(ShelfProPriceChip), findsNothing);
      expect(inBar(find.text('KD 2.250')), findsOneWidget);
    });
  });
}
