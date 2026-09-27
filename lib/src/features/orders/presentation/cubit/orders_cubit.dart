import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/usecase/watch_params.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/cancel_order_request.dart';
import '../../domain/entities/orders_page.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/get_order_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/watch_orders_usecase.dart';
import 'orders_state.dart';

/// The orders list: the first page paints from the device copy (offline
/// too), then the server's; pull-to-refresh; "load more" (the shared paged
/// flow: one page at a time, stale pages dropped, a failed page waits for a
/// tap — or the connection); one cancel at a time; and single-order
/// refreshes when the customer comes back from tracking.
class OrdersCubit extends Cubit<OrdersState>
    with
        SafeCubitMixin<OrdersState>,
        SnapshotLoaderMixin<OrdersState>,
        ScreenLoaderMixin<OrdersState>,
        PagedScreenMixin<OrdersState> {
  OrdersCubit({
    required this._watchFirstPage,
    required this._getOrders,
    required this._getOrder,
    required this._cancelOrder,
  }) : super(OrdersState());

  final WatchOrdersUseCase _watchFirstPage;
  final GetOrdersUseCase _getOrders;
  final GetOrderUseCase _getOrder;
  final CancelOrderUseCase _cancelOrder;

  /// First load, or the retry of a failed one: the skeleton only while
  /// nothing is on screen.
  Future<void> load() {
    showLoading();
    return _readFirstPage(WatchParams.cached);
  }

  /// Pull-to-refresh, or the tab coming back: the server's first page; the
  /// list stays on screen meanwhile. One at a time.
  @override
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    safeEmit(state.copyWith(isRefreshing: true));
    await _readFirstPage(WatchParams.fresh);
    // A failed refresh keeps the list and its failure; the spinner stops
    // either way.
    if (state.isRefreshing) {
      safeEmit(state.copyWith(isRefreshing: false, load: state.load));
    }
  }

  Future<void> _readFirstPage(WatchParams params) => readScreen<OrdersPage>(
    _watchFirstPage(params),
    show: (state, snapshot) => state.copyWith(
      feed: state.feed.replace(snapshot.data),
      isRefreshing: false,
    ),
  );

  /// The end of the list came into reach. After a failed page it waits for
  /// the "Load more" tap — or the connection to return — ([retry] = true)
  /// instead of asking again on every scroll.
  @override
  Future<void> loadMore({bool retry = false}) => loadNextPage<OrdersPage>(
    hasMore: state.feed.hasMore,
    retry: retry,
    fetch: () => _getOrders(GetOrdersParams(page: state.feed.page + 1)),
    merge: (state, page) => state.copyWith(feed: state.feed.merge(page)),
  );

  /// Cancels one order; a second request while one is in flight is ignored.
  Future<bool> cancel(CancelOrderRequest request) async {
    if (state.cancellingId != null) return false;
    safeEmit(state.copyWith(cancellingId: request.orderId));
    final result = await _cancelOrder(CancelOrderParams(request));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(clearCancelling: true, load: state.load.noted(failure)),
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
      (failure) => noteFailure(failure, on: FailedCall.read),
      applyOrder,
    );
  }

  /// An order known from elsewhere (just placed, just cancelled).
  void applyOrder(OrderEntity order) =>
      safeEmit(state.copyWith(feed: state.feed.withOrder(order)));
}
