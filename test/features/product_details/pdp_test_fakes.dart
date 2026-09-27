// Shared fakes of the product page's widget tests: the app-global cart as a
// real Cubit that keeps lines (so the buy bar's stepper follows it), stub
// use cases, a signed-out session, the page's new i18n keys, the English
// strings the widget tests read and a fixed-step settle.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' show EasyLocalization;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_line_ref.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_state.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_reviews.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/get_product_offer_usecase.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/get_product_reviews_usecase.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/watch_product_detail_usecase.dart';
import 'package:hero_mart/src/features/product_details/domain/usecases/watch_product_reviews_usecase.dart';

import '../../core/data/snapshot_test_fakes.dart';
import '../auth/auth_test_fakes.dart';

/// Keys the product page added. Until the lead lands them in
/// `assets/i18n/{en,ar}.json`, the tests speak them themselves (an existing
/// value always wins).
const Map<String, Map<String, String>> kNewProductKeys = {
  'en': {
    'more': 'More',
    'less': 'Less',
    'shop_more_for_less': 'Shop more for less',
    'close': 'Close',
  },
  'ar': {
    'more': 'المزيد',
    'less': 'أقل',
    'shop_more_for_less': 'تسوّق أكثر بأقل',
    'close': 'إغلاق',
  },
};

/// [translations] with the page's new keys filled in for [code].
Map<String, dynamic> withNewProductKeys(
  Map<String, dynamic> translations,
  String code,
) {
  final product = Map<String, dynamic>.of(
    translations['product'] as Map<String, dynamic>,
  );
  kNewProductKeys[code]!.forEach(
    (key, value) => product.putIfAbsent(key, () => value),
  );
  return <String, dynamic>{...translations, 'product': product};
}

/// Loads the app's English strings, [kNewProductKeys] filled in, for widget
/// tests that read `.tr()` without an `EasyLocalization` root. Call it from
/// `setUpAll`, after `SharedPreferences.setMockInitialValues`.
Future<void> speakEnglish() async {
  await EasyLocalization.ensureInitialized();
  final raw = await rootBundle.loadString('assets/i18n/en.json');
  Localization.load(
    const Locale('en'),
    translations: Translations(
      withNewProductKeys(json.decode(raw) as Map<String, dynamic>, 'en'),
    ),
  );
}

/// [frames] frames of 100 ms: long enough for a page transition or a photo
/// flight to land, where `pumpAndSettle` would wait on a looping animation.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The product read: [served], from the server.
class StubWatchDetail implements WatchProductDetailUseCase {
  const StubWatchDetail(this.served);

  final ProductDetail served;

  @override
  Stream<DataSnapshot<ProductDetail>> call(WatchProductDetailParams params) =>
      networkRead(Future.value(Right<Failure, ProductDetail>(served)));
}

/// The buy bar's promo offer: [served] (none by default).
class StubGetOffer implements GetProductOfferUseCase {
  const StubGetOffer([this.served]);

  final OfferEntity? served;

  @override
  Future<Either<Failure, OfferEntity?>> call(
    GetProductOfferParams params,
  ) async => Right(served);
}

class StubGetReviews implements GetProductReviewsUseCase {
  const StubGetReviews([this.served = ProductReviews.empty]);

  final ProductReviews served;

  @override
  Future<Either<Failure, ProductReviews>> call(
    GetProductReviewsParams params,
  ) async => Right(served);
}

/// The first reviews page: [served], from the server.
class StubWatchReviews implements WatchProductReviewsUseCase {
  const StubWatchReviews([this.served = ProductReviews.empty]);

  final ProductReviews served;

  @override
  Stream<DataSnapshot<ProductReviews>> call(WatchProductReviewsParams params) =>
      networkRead(Future.value(Right<Failure, ProductReviews>(served)));
}

AuthSessionCubit signedOutSession() => AuthSessionCubit(
  restoreSession: FakeRestoreSessionUseCase(const Right(null)),
  logout: FakeLogoutUseCase(),
  watchExpiry: FakeWatchSessionExpiryUseCase(),
  getCachedCustomer: FakeGetCachedCustomerUseCase(),
  saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
  clearCachedCustomer: FakeClearCachedCustomerUseCase(),
);

/// The app-global cart: records what the page asks of it and keeps the
/// lines, the way the real mirror projects a tap at once.
class FakeCartCubit extends Cubit<CartState> implements CartCubit {
  FakeCartCubit([super.initialState = const CartState()]);

  /// A cart already holding [quantity] of [product] ([variantId]).
  factory FakeCartCubit.holding(
    CatalogProductEntity product,
    int quantity, {
    String? variantId,
  }) {
    final cart = FakeCartCubit();
    cart._shift(product, variantId, quantity);
    return cart;
  }

  final List<(String, String?, int)> adds = [];
  final List<String> removes = [];
  int increments = 0;
  int decrements = 0;

  @override
  void addCatalogProduct(
    CatalogProductEntity product, {
    String? variantId,
    int quantity = 1,
  }) {
    adds.add((product.id, variantId, quantity));
    _shift(product, variantId, quantity);
  }

  @override
  void removeProduct(String productId) => removes.add(productId);

  @override
  void increment(CartLineEntity line) {
    increments++;
    _shift(line.product, line.variantId, 1);
  }

  @override
  void decrement(CartLineEntity line) {
    decrements++;
    _shift(line.product, line.variantId, -1);
  }

  void _shift(CatalogProductEntity product, String? variantId, int delta) {
    final ref = CartLineRef(product.id, variantId);
    final next = (state.cart.lineFor(ref)?.quantity ?? 0) + delta;
    final lines = <CartLineEntity>[
      for (final line in state.cart.lines)
        if (line.ref != ref) line,
      if (next > 0)
        CartLineEntity(
          key: 'line-$ref',
          product: product,
          quantity: next,
          unitPriceFils: product.priceFils,
          lineTotalFils: product.priceFils * next,
          variantId: variantId,
        ),
    ];
    final byProduct = <String, int>{};
    var total = 0;
    for (final line in lines) {
      byProduct[line.product.id] =
          (byProduct[line.product.id] ?? 0) + line.quantity;
      total += line.quantity;
    }
    emit(
      CartState(
        cart: CartEntity(lines: lines, itemCount: total),
        isRestored: true,
        quantityByProduct: byProduct,
        revision: state.revision + 1,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
