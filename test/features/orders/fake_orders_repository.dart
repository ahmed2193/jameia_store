import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/data/mappers/order_mapper.dart';
import 'package:jameia_mart/src/core/data/models/order_model.dart';
import 'package:jameia_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:jameia_mart/src/core/domain/entities/order_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/cancel_order_request.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/orders_page.dart';
import 'package:jameia_mart/src/features/orders/domain/entities/product_review_request.dart';
import 'package:jameia_mart/src/features/orders/domain/repositories/orders_repository.dart';

import '../../core/data/snapshot_test_fakes.dart';
import 'order_test_fixtures.dart';

/// Scripted orders repository: records the calls, can hold one open and can
/// fail the next call of a kind.
///
/// The `watch…` reads stream like the cached repository: the saved copy
/// ([savedFirstPage] / [savedOrder]) first when set — a forced read skips
/// it — then the scripted reply, recorded as the same `getOrders:1` /
/// `getOrder:<id>` call.
class FakeOrdersRepository implements OrdersRepository {
  final List<String> calls = <String>[];

  /// The `forceRefresh` of every `watch…` read, in order.
  final List<bool> forcedReads = <bool>[];

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

  /// When set, the first page answers with one order per status instead of a
  /// single `placed` row — a history with running, done and cancelled orders.
  List<String>? statuses;

  /// The status the detail / cancel calls answer with.
  String detailStatus = 'placed';
  int reviewCalls = 0;

  /// The device copies a `watch…` read shows first.
  OrdersPage? savedFirstPage;
  OrderEntity? savedOrder;

  OrderEntity order({String id = 'o1', String status = 'placed'}) =>
      OrderModel.fromJson(orderJson(id: id, status: status)).toEntity();

  @override
  Stream<DataSnapshot<OrdersPage>> watchFirstPage({
    required int limit,
    bool forceRefresh = false,
  }) {
    forcedReads.add(forceRefresh);
    return networkRead(
      getOrders(page: 1, limit: limit),
      saved: forceRefresh ? null : savedFirstPage,
    );
  }

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
    final mixed = statuses;
    return Right(
      OrdersPage(
        orders: mixed == null || page != 1
            ? <OrderEntity>[order(id: 'o$page')]
            : <OrderEntity>[
                for (var i = 0; i < mixed.length; i++)
                  order(id: 'o$i', status: mixed[i]),
              ],
        page: page,
        hasMore: page < pages,
        total: pages,
      ),
    );
  }

  @override
  Stream<DataSnapshot<OrderEntity>> watchOrder(
    String orderId, {
    bool forceRefresh = false,
  }) {
    forcedReads.add(forceRefresh);
    return networkRead(
      getOrder(orderId),
      saved: forceRefresh ? null : savedOrder,
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
