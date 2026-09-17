import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/data/jameia_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cart_snapshot.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';
import '../models/cart_model.dart';

/// Offline cart repository — owns the authoritative in-memory cart, mirrors it
/// to [CartLocalDataSource] after every mutation, and rehydrates lines from the
/// [JameiaRepository] catalogue on first read.
///
/// The mutation methods are `async` but contain no `await` before returning
/// (persistence is fire-and-forget via [unawaited]), so the in-memory map is
/// updated **synchronously** at call time. That keeps rapid taps race-free: a
/// second `add` always observes the first one's result.
class CartRepositoryImpl implements CartRepository {
  final CartLocalDataSource local;
  final JameiaRepository catalog;

  CartRepositoryImpl({required this.local, required this.catalog});

  final Map<String, CartItem> _items = {};
  String? _shopId;
  bool _hydrated = false;

  CartSnapshot get _snapshot => CartSnapshot(
    items: Map<String, CartItem>.unmodifiable(_items),
    shopId: _shopId,
  );

  @override
  Future<Either<Failure, CartSnapshot>> getCart() async {
    if (!_hydrated) {
      _hydrate();
      _hydrated = true;
    }
    return Right(_snapshot);
  }

  /// Rebuild live [CartItem]s from the persisted [CartModel], dropping any line
  /// whose product no longer exists in the catalogue (graceful catalogue drift).
  void _hydrate() {
    final model = local.read();
    if (model == null) return;
    for (final line in model.lines) {
      final product = catalog.productById(line.productId);
      if (product == null) continue; // product gone → skip the line
      ProductVariant? variant;
      if (line.variantSku != null) {
        for (final v in product.variants) {
          if (v.sku == line.variantSku) {
            variant = v;
            break;
          }
        }
      }
      final item = CartItem(
        product: product,
        shopId: line.shopId,
        variant: variant,
        qty: line.qty,
        unitPriceOverride: line.unitPriceOverride,
      );
      _items[item.lineKey] = item;
    }
    _shopId =
        model.shopId ?? (_items.isEmpty ? null : _items.values.first.shopId);
  }

  @override
  Future<Either<Failure, CartSnapshot>> addLine({
    required Product product,
    required String shopId,
    ProductVariant? variant,
    double? unitPrice,
    int qty = 1,
  }) async {
    try {
      // Starting a cart in a different shop clears the previous one.
      if (_shopId != null && _shopId != shopId) _items.clear();
      _shopId = shopId;
      final add = qty < 1 ? 1 : qty;
      final line = CartItem(
        product: product,
        shopId: shopId,
        variant: variant,
        qty: add,
        unitPriceOverride: unitPrice,
      );
      final key = line.lineKey;
      final existing = _items[key];
      _items[key] = existing == null
          ? line
          : existing.copyWith(qty: existing.qty + add);
      return _persistAndReturn();
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartSnapshot>> updateQty({
    required String lineKey,
    required int qty,
  }) async {
    try {
      final existing = _items[lineKey];
      if (existing == null) return Right(_snapshot);
      if (qty <= 0) {
        _items.remove(lineKey);
      } else {
        _items[lineKey] = existing.copyWith(qty: qty);
      }
      if (_items.isEmpty) _shopId = null;
      return _persistAndReturn();
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartSnapshot>> removeLine({
    required String lineKey,
  }) async {
    try {
      _items.remove(lineKey);
      if (_items.isEmpty) _shopId = null;
      return _persistAndReturn();
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartSnapshot>> clear() async {
    try {
      _items.clear();
      _shopId = null;
      unawaited(_safeClear());
      return Right(_snapshot);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Fire-and-forget persist (best-effort — never blocks the UI), then return
  /// the fresh snapshot synchronously.
  Either<Failure, CartSnapshot> _persistAndReturn() {
    final model = CartModel(
      shopId: _shopId,
      lines: _items.values
          .map(CartLineModel.fromCartItem)
          .toList(growable: false),
    );
    unawaited(_safeWrite(model));
    return Right(_snapshot);
  }

  Future<void> _safeWrite(CartModel model) async {
    try {
      await local.write(model);
    } catch (_) {
      /* best-effort persistence */
    }
  }

  Future<void> _safeClear() async {
    try {
      await local.clear();
    } catch (_) {
      /* best-effort persistence */
    }
  }

  @override
  String? checkoutShopId(String? cartShopId) {
    // Prefer the cart's own shop when the router can resolve it; otherwise fall
    // back to the first catalogue shop (unified basket → synthetic `jameia`).
    final resolved = catalog.shopById(cartShopId ?? '');
    if (resolved != null) return resolved.id;
    final shops = catalog.shops;
    return shops.isNotEmpty ? shops.first.id : null;
  }
}
