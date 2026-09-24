import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/cancel_order_request.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/get_order_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import 'orders_state.dart';

/// The orders list: first page, pull-to-refresh, "load more" guarded against
/// re-entry and stale pages (a refresh started after a load-more drops the
/// older reply), one cancel at a time, and single-order refreshes when the
/// customer comes back from tracking.
class OrdersCubit extends Cubit<OrdersState> with SafeCubitMixin<OrdersState> {
  OrdersCubit({
    required this._getOrders,
    required this._getOrder,
    required this._cancelOrder,
  }) : super(OrdersState());

  final GetOrdersUseCase _getOrders;
  final GetOrderUseCase _getOrder;
  final CancelOrderUseCase _cancelOrder;

  int _generation = 0;

  Future<void> load() async {
    safeEmit(state.copyWith(status: OrdersStatus.loading));
    await _loadFirstPage(OrdersAction.load);
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    safeEmit(state.copyWith(isRefreshing: true));
    await _loadFirstPage(OrdersAction.refresh);
  }

  Future<void> _loadFirstPage(OrdersAction action) async {
    final generation = ++_generation;
    final result = await _getOrders(const GetOrdersParams());
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.feed.isEmpty ? OrdersStatus.error : OrdersStatus.loaded,
          isRefreshing: false,
          isLoadingMore: false,
          failure: failure,
          failedAction: action,
        ),
      ),
      (page) => safeEmit(
        state.copyWith(
          status: OrdersStatus.loaded,
          feed: state.feed.replace(page),
          isRefreshing: false,
          isLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isRefreshing || !state.feed.hasMore) {
      return;
    }
    final generation = _generation;
    safeEmit(state.copyWith(isLoadingMore: true));
    final result = await _getOrders(GetOrdersParams(page: state.feed.page + 1));
    if (generation != _generation) return; // a refresh replaced the feed
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isLoadingMore: false,
          failure: failure,
          failedAction: OrdersAction.loadMore,
        ),
      ),
      (page) => safeEmit(
        state.copyWith(isLoadingMore: false, feed: state.feed.merge(page)),
      ),
    );
  }

  /// Cancels one order; a second request while one is in flight is ignored.
  Future<bool> cancel(CancelOrderRequest request) async {
    if (state.cancellingId != null) return false;
    safeEmit(state.copyWith(cancellingId: request.orderId));
    final result = await _cancelOrder(CancelOrderParams(request));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          clearCancelling: true,
          failure: failure,
          failedAction: OrdersAction.cancel,
        ),
      ),
      (order) => safeEmit(
        state.copyWith(
          clearCancelling: true,
          feed: state.feed.withOrder(order),
        ),
      ),
    );
    return result.isRight();
  }

  /// One order may have moved while its tracking page was open.
  Future<void> refreshOrder(String orderId) async {
    final result = await _getOrder(GetOrderParams(orderId));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          failure: failure,
          failedAction: OrdersAction.refreshOrder,
        ),
      ),
      applyOrder,
    );
  }

  /// An order known from elsewhere (just placed, just cancelled).
  void applyOrder(OrderEntity order) =>
      safeEmit(state.copyWith(feed: state.feed.withOrder(order)));
}
