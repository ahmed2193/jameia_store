import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/models/products_page_model.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/network/locale_provider.dart';

/// The "deals you might have missed" read the checkout waits on before its
/// content paints — `GET /v1/products?onSale&inStock&sort=discount` through
/// the shared [CatalogRemoteDataSource] — kept per language for [railTtl]
/// and shared while in flight. Reopening checkout within that window (back
/// from the address list, a product page, the cart) paints at once instead
/// of waiting on the rail again, and a reply that lands after the page
/// stopped waiting (`CheckoutRailCubit.settleLimit`) still serves the next
/// open. Throws `AppException` only.
abstract class CheckoutRailDataSource {
  /// The first [limit] products of the rail query (page 1).
  Future<ProductsPageModel> getRailPage({required int limit});
}

class CheckoutRailDataSourceImpl implements CheckoutRailDataSource {
  CheckoutRailDataSourceImpl(
    this._catalog,
    this._locale, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CatalogRemoteDataSource _catalog;
  final LocaleProvider _locale;

  /// Injectable so the cache window is testable.
  final DateTime Function() _now;

  /// On sale and in stock, the biggest discount first.
  static const CatalogProductQuery railQuery = CatalogProductQuery(
    inStockOnly: true,
    onSaleOnly: true,
    sort: CatalogProductSort.discount,
  );

  /// Short: stock and sale prices move, so the rail is reused only across a
  /// quick back-and-forth (the checkout still drops what went out of stock
  /// or is in the basket).
  static const Duration railTtl = Duration(minutes: 2);

  ProductsPageModel? _page;
  String _key = '';
  DateTime? _readAt;

  Future<ProductsPageModel>? _inFlight;
  String _inFlightKey = '';

  @override
  Future<ProductsPageModel> getRailPage({required int limit}) async {
    // Product names are resolved by `Accept-Language`.
    final key = '${_locale.languageCode}/$limit';
    final cached = _page;
    final readAt = _readAt;
    if (cached != null &&
        _key == key &&
        readAt != null &&
        _now().difference(readAt) < railTtl) {
      return cached;
    }
    final inFlight = _inFlight;
    if (inFlight != null && _inFlightKey == key) return inFlight;
    final read = _read(key, limit);
    _inFlight = read;
    _inFlightKey = key;
    try {
      return await read;
    } finally {
      if (identical(_inFlight, read)) _inFlight = null;
    }
  }

  Future<ProductsPageModel> _read(String key, int limit) async {
    final page = await _catalog.getProducts(
      query: railQuery,
      page: 1,
      limit: limit,
    );
    _page = page;
    _key = key;
    _readAt = _now();
    return page;
  }
}
