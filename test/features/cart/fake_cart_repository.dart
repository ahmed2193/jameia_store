import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_item_request.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_line_ref.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/domain/repositories/cart_repository.dart';

/// Scripted cart repository: records what the cubit asked for, lets the test
/// push snapshots, hold one operation open and fail the next one.
class FakeCartRepository implements CartRepository {
  final StreamController<CartSnapshot> controller =
      StreamController<CartSnapshot>.broadcast();
  final List<String> calls = <String>[];
  CartSnapshot snapshot = const CartSnapshot();

  /// When set, the next server-confirmed operation waits on it.
  Completer<void>? gate;

  /// Returned by the next server-confirmed operation.
  Failure? failure;

  void push(CartSnapshot next) {
    snapshot = next;
    controller.add(next);
  }

  Future<void> dispose() => controller.close();

  Future<Either<Failure, Unit>> _op(String name) async {
    calls.add(name);
    final gate = this.gate;
    if (gate != null) {
      this.gate = null;
      await gate.future;
    }
    final failure = this.failure;
    this.failure = null;
    return failure == null ? const Right(unit) : Left(failure);
  }

  Either<Failure, Unit> _sync(String name) {
    calls.add(name);
    return const Right(unit);
  }

  @override
  Stream<CartSnapshot> watch() async* {
    yield snapshot;
    yield* controller.stream;
  }

  @override
  Future<Either<Failure, Unit>> restore() => _op('restore');

  @override
  Future<Either<Failure, Unit>> syncOwner(String ownerId) =>
      _op('syncOwner:$ownerId');

  @override
  Future<Either<Failure, Unit>> fetch() => _op('fetch');

  @override
  Future<Either<Failure, Unit>> flush() => _op('flush');

  @override
  Either<Failure, Unit> adjustLine({
    required CatalogProductEntity product,
    String? variantId,
    required int delta,
  }) => _sync('adjust:${product.id}:${variantId ?? ''}:$delta');

  @override
  Either<Failure, Unit> setLineQuantity(CartLineRef ref, int quantity) =>
      _sync('set:$ref:$quantity');

  @override
  Either<Failure, Unit> removeLine(CartLineRef ref) => _sync('remove:$ref');

  @override
  Future<Either<Failure, Unit>> addItems(List<CartItemRequest> items) =>
      _op('addItems:${items.length}');

  @override
  Future<Either<Failure, Unit>> clear() => _op('clear');

  @override
  Future<Either<Failure, Unit>> applyCoupon(String code) =>
      _op('applyCoupon:$code');

  @override
  Future<Either<Failure, Unit>> removeCoupon() => _op('removeCoupon');

  @override
  Future<Either<Failure, Unit>> applyLoyalty(int points) =>
      _op('applyLoyalty:$points');

  @override
  Future<Either<Failure, Unit>> removeLoyalty() => _op('removeLoyalty');

  @override
  Future<Either<Failure, Unit>> setExpress({required bool enabled}) =>
      _op('express:$enabled');

  @override
  Future<Either<Failure, Unit>> reset() => _op('reset');
}
