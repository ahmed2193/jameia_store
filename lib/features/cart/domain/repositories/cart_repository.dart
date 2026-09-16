import 'package:dartz/dartz.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart_snapshot.dart';

/// Cart persistence + mutation boundary. Every method returns the full
/// [CartSnapshot] after the operation so the cubit can emit a fresh state.
abstract class CartRepository {
  /// Hydrate (the first call rebuilds lines from local storage) and return the
  /// current cart.
  Future<Either<Failure, CartSnapshot>> getCart();

  /// Add [qty] units of a product (optionally a specific [variant]) to the cart.
  /// Starting a cart in a different [shopId] replaces the previous one.
  Future<Either<Failure, CartSnapshot>> addLine({
    required Product product,
    required String shopId,
    ProductVariant? variant,
    double? unitPrice,
    int qty,
  });

  /// Set the absolute quantity of a line (qty &lt;= 0 removes it).
  Future<Either<Failure, CartSnapshot>> updateQty({
    required String lineKey,
    required int qty,
  });

  /// Remove an entire line regardless of its quantity.
  Future<Either<Failure, CartSnapshot>> removeLine({required String lineKey});

  /// Empty the cart.
  Future<Either<Failure, CartSnapshot>> clear();

  /// Resolve a router-resolvable checkout shop id for the active cart (B2).
  ///
  /// The unified basket's [CartSnapshot.shopId] is the synthetic `jameia`, which
  /// the router's `shopById` doesn't carry — fall back to the first catalogue
  /// shop (the same idiom the Orders reorder path uses). Returns `null` only when
  /// the catalogue is empty. A pure catalogue read (cannot fail), so it stays
  /// plain sync — no `Either<Failure, T>` ceremony — and keeps the presentation
  /// layer from reaching into `core/data/keeta_repository.dart` directly.
  String? checkoutShopId(String? cartShopId);
}
