// The deals strip over the checkout bar and the "Buy more, save more" sheet
// it opens: headlines per cart state, the offer cards, the products under
// the selected one, and the basket bar at the sheet's foot.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_applied_offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_offer_progress_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/domain/usecases/get_deal_products_usecase.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_deals_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_state.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_checkout_bar.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/deals/cart_deal_card.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/deals/cart_deals_sheet.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/deals/cart_deals_strip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../product_details/pdp_test_fakes.dart';

const String _dairyId = 'c-dairy';

const CatalogProductEntity _eggs = CatalogProductEntity(
  id: 'eggs',
  slug: 'eggs',
  name: 'Fresh Eggs (30)',
  priceFils: 2250,
  stock: 20,
);

const CartAppliedOfferEntity _freeDelivery = CartAppliedOfferEntity(
  offerId: 'of-free-delivery',
  name: 'Free delivery over 5 KWD',
  reward: OfferRewardEntity(type: OfferRewardType.freeDelivery),
);

const CartOfferProgressEntity _dairy = CartOfferProgressEntity(
  offerId: 'of-dairy',
  name: '2 KWD off dairy',
  kind: OfferProgressKind.category,
  currentValue: 1,
  targetValue: 3,
  remainingValue: 2,
  contextId: _dairyId,
  contextName: 'Dairy & Eggs',
  reward: OfferRewardEntity(type: OfferRewardType.fixedDiscount, amountFils: 2000),
);

CartState _state({
  List<CartAppliedOfferEntity> applied = const [],
  List<CartOfferProgressEntity> progress = const [],
}) => CartState(
  isRestored: true,
  cart: CartEntity(
    itemCount: 3,
    lines: const [CartLineEntity(key: 'l1', product: _eggs, quantity: 3)],
    appliedOffers: applied,
    offerProgress: progress,
    totals: const CartTotalsEntity(
      subtotalFils: 6750,
      totalFils: 6750,
      freeDelivery: true,
    ),
  ),
);

/// On sale: bananas; the dairy category: milk.
class _Deals implements GetDealProductsUseCase {
  final List<String?> asked = [];

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> call(
    GetDealProductsParams params,
  ) async {
    asked.add(params.categoryId);
    return Right([
      CatalogProductEntity(
        id: params.categoryId == null ? 'banana' : 'milk',
        slug: 'x',
        name: params.categoryId == null ? 'Fresh banana' : 'Fresh milk',
        priceFils: 625,
        stock: 9,
      ),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final raw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(raw) as Map<String, dynamic>),
    );
  });

  Future<_Deals> pump(WidgetTester tester, CartState state) async {
    final cart = FakeCartCubit(state);
    final session = signedOutSession();
    final deals = _Deals();
    final dealsCubit = CartDealsCubit(deals);
    addTearDown(() async {
      await cart.close();
      await session.close();
      await dealsCubit.close();
    });
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>.value(value: cart),
          BlocProvider<AuthSessionCubit>.value(value: session),
          BlocProvider<CartDealsCubit>.value(value: dealsCubit),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CartDealsStrip(), CartCheckoutBar()],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return deals;
  }

  testWidgets('the strip names the next offer to unlock', (tester) async {
    await pump(tester, _state(applied: [_freeDelivery], progress: [_dairy]));

    expect(find.text('Add 2 more to get KD 2.000 off'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
  });

  testWidgets('every offer earned: the best deal', (tester) async {
    await pump(tester, _state(applied: [_freeDelivery]));

    expect(
      find.textContaining("Congrats! You've got the best deal!"),
      findsOneWidget,
    );
  });

  testWidgets('no offers: no strip', (tester) async {
    await pump(tester, _state());

    expect(find.text('Add item'), findsNothing);
    expect(find.byType(CartCheckoutBar), findsOneWidget);
  });

  testWidgets('"Add item" opens the sheet on the next deal, cards switch', (
    tester,
  ) async {
    final deals = await pump(
      tester,
      _state(applied: [_freeDelivery], progress: [_dairy]),
    );

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(find.byType(CartDealsSheet), findsOneWidget);
    expect(find.text('Buy more, save more'), findsOneWidget);
    expect(find.byType(CartDealCard), findsNWidgets(2));
    expect(find.text('Offer applied!'), findsOneWidget);
    expect(find.text('Add 2 more from Dairy & Eggs'), findsOneWidget);
    // The next deal is the dairy one: its category's products.
    expect(deals.asked, [_dairyId]);
    expect(find.text('Fresh milk'), findsOneWidget);
    // The sheet has its own basket bar.
    expect(
      find.descendant(
        of: find.byType(CartDealsSheet),
        matching: find.byType(CartCheckoutBar),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Free delivery over 5 KWD'));
    await tester.pumpAndSettle();

    expect(deals.asked, [_dairyId, null]);
    expect(find.text('Fresh banana'), findsOneWidget);
    expect(find.text('Fresh milk'), findsNothing);
  });
}
