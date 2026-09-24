import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/cart_item_request.dart';
import '../../../../core/domain/entities/cart_line_ref.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/cart_snapshot.dart';

/// The cart as the app sees it: an offline-first mirror of the server cart.
///
/// Quantity changes ([adjustLine], [setLineQuantity], [removeLine]) apply
/// locally at once and reach the server in coalesced, serialized requests;
/// [watch] streams the projected result. Everything else ([addItems],
/// [clear], coupon / loyalty / express) waits for the server and answers with
/// its `Either`; the stream carries the new cart as well.
abstract class CartRepository {
  /// Current snapshot first, then every change.
  Stream<CartSnapshot> watch();

  /// Loads the saved mirror so the first frame shows the last known cart.
  Future<Either<Failure, Unit>> restore();

  /// Tells the mirror who owns the session now (a customer id or
  /// [guestOwnerId]). A mirror of somebody else is dropped; then the server
  /// cart is fetched, the pending changes are re-based on it and flushed.
  Future<Either<Failure, Unit>> syncOwner(String ownerId);

  /// `GET /v1/cart` (queued behind in-flight writes).
  Future<Either<Failure, Unit>> fetch();

  /// Sends whatever is still pending now (no debounce).
  Future<Either<Failure, Unit>> flush();

  /// `+delta` / `-delta` pieces of a product (a variant product names the
  /// variant); [product] draws a line the server does not have yet.
  Either<Failure, Unit> adjustLine({
    required CatalogProductEntity product,
    String? variantId,
    required int delta,
  });

  /// Absolute quantity for an existing line; `0` removes it.
  Either<Failure, Unit> setLineQuantity(CartLineRef ref, int quantity);

  Either<Failure, Unit> removeLine(CartLineRef ref);

  /// `POST /v1/cart/items` in one batch (reorder); waits for the server.
  Future<Either<Failure, Unit>> addItems(List<CartItemRequest> items);

  /// `DELETE /v1/cart`.
  Future<Either<Failure, Unit>> clear();

  Future<Either<Failure, Unit>> applyCoupon(String code);

  Future<Either<Failure, Unit>> removeCoupon();

  Future<Either<Failure, Unit>> applyLoyalty(int points);

  Future<Either<Failure, Unit>> removeLoyalty();

  Future<Either<Failure, Unit>> setExpress({required bool enabled});

  /// Forgets the cart, the pending changes and the mirror (sign-out, order
  /// placed); in-flight replies are dropped.
  Future<Either<Failure, Unit>> reset();

  static const String guestOwnerId = 'guest';
}
