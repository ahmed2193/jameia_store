import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/data/mappers/order_mapper.dart';
import 'package:jameia_mart/src/core/data/models/order_model.dart';
import 'package:jameia_mart/src/core/domain/entities/order_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/cancel_order_request.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/orders_page.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/product_review_request.dart';
import 'package:jameia_mart/src/features/orders/domain/repositories/orders_repository.dart';

import 'order_test_fixtures.dart';

/// Scripted orders repository: records the calls, can hold one open and can
/// fail the next call of a kind.
class FakeOrdersRepository implements OrdersRepository {
  final List<String> calls = <String>[];

  /// Gate for the next [getOrders] call (a stale page in flight).
  Completer<void>? listGate;

  /// Gate for the next [cancelOrder] call (a cancel race).
  Completer<void>? cancelGate;

  Failure? listFailure;
  Failure? detailFailure;
  Failure? cancelFailure;
  Failure? reviewFailure;

  /// Fails every review from this call on (1 = the second one fails).
  int? reviewFailureAfter;

  /// How many pages the fake serves.
  int pages = 1;

  /// The status the detail / cancel calls answer with.
  String detailStatus = 'placed';
  int reviewCalls = 0;

  OrderEntity order({String id = 'o1', String status = 'placed'}) =>
      OrderModel.fromJson(orderJson(id: id, status: status)).toEntity();

  @override
  Future<Either<Failure, OrdersPage>> getOrders({
    required int page,
    required int limit,
  }) async {
    calls.add('getOrders:$page');
    final gate = listGate;
    if (gate != null) {
      listGate = null;
      await gate.future;
    }
    final failure = listFailure;
    listFailure = null;
    if (failure != null) return Left(failure);
    return Right(
      OrdersPage(
        orders: <OrderEntity>[order(id: 'o$page')],
        page: page,
        hasMore: page < pages,
        total: pages,
      ),
    );
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrder(String orderId) async {
    calls.add('getOrder:$orderId');
    final failure = detailFailure;
    detailFailure = null;
    if (failure != null) return Left(failure);
    return Right(order(id: orderId, status: detailStatus));
  }

  @override
  Future<Either<Failure, OrderEntity>> cancelOrder(
    CancelOrderRequest request,
  ) async {
    calls.add('cancel:${request.orderId}:${request.reason.wireValue}');
    final gate = cancelGate;
    if (gate != null) {
      cancelGate = null;
      await gate.future;
    }
    final failure = cancelFailure;
    cancelFailure = null;
    if (failure != null) return Left(failure);
    return Right(order(id: request.orderId, status: 'cancelled'));
  }

  @override
  Future<Either<Failure, Unit>> submitReview(
    ProductReviewRequest request,
  ) async {
    calls.add('review:${request.productId}:${request.rating}');
    reviewCalls++;
    final after = reviewFailureAfter;
    if (after != null && reviewCalls > after) {
      return const Left(ServerFailure('nope', statusCode: 400));
    }
    final failure = reviewFailure;
    reviewFailure = null;
    if (failure != null) return Left(failure);
    return const Right(unit);
  }
}
