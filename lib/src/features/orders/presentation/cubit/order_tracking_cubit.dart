import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_status.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/cancel_order_request.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/get_order_usecase.dart';
import 'order_tracking_state.dart';

/// One order's live status. Polls `GET /v1/orders/{id}` every [pollInterval]
/// while the page is visible and the order can still move; stops on a
/// terminal status, when the page hides, and on close. Cancel runs once.
class OrderTrackingCubit extends Cubit<OrderTrackingState>
    with SafeCubitMixin<OrderTrackingState> {
  OrderTrackingCubit({
    required this._getOrder,
    required this._cancelOrder,
    this.pollInterval = defaultPollInterval,
  }) : super(const OrderTrackingState());

  /// The backend asks for at least 30 s between polls.
  static const Duration defaultPollInterval = Duration(seconds: 30);

  final GetOrderUseCase _getOrder;
  final CancelOrderUseCase _cancelOrder;
  final Duration pollInterval;

  String _orderId = '';
  bool _visible = true;
  bool _polling = false;
  Timer? _timer;
  int _generation = 0;

  /// Whether this cubit is keeping the order up to date — true across the
  /// gap where a poll is in flight and no timer is armed yet, which is what
  /// the page (and a test) means by "still polling".
  bool get isPolling => _polling;

  Future<void> load(String orderId) async {
    _orderId = orderId;
    safeEmit(state.copyWith(status: OrderTrackingStatus.loading));
    await _fetch(OrderTrackingAction.load);
  }

  Future<void> refresh() async {
    if (state.isRefreshing || _orderId.isEmpty) return;
    safeEmit(state.copyWith(isRefreshing: true));
    await _fetch(OrderTrackingAction.refresh);
  }

  /// The page tells the cubit when it is on screen; polling follows.
  void setVisible(bool visible) {
    _visible = visible;
    _schedule();
  }

  Future<void> _fetch(OrderTrackingAction action) async {
    final generation = ++_generation;
    final result = await _getOrder(GetOrderParams(_orderId));
    if (generation != _generation) return;
    if (action == OrderTrackingAction.poll &&
        result.isLeft() &&
        state.order != null) {
      // Nobody asked for this request: keep the order on screen and try
      // again on the next tick instead of raising a toast every interval.
      _schedule();
      return;
    }
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.order == null
              ? OrderTrackingStatus.error
              : OrderTrackingStatus.loaded,
          isRefreshing: false,
          failure: failure,
          failedAction: action,
        ),
      ),
      (order) => safeEmit(
        state.copyWith(
          status: OrderTrackingStatus.loaded,
          order: order,
          isRefreshing: false,
        ),
      ),
    );
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final order = state.order;
    _polling = _visible && order != null && !order.isTerminal && !isClosed;
    if (!_polling) return;
    _timer = Timer(pollInterval, () {
      _timer = null;
      if (!isClosed) unawaited(_fetch(OrderTrackingAction.poll));
    });
  }

  Future<bool> cancel({
    required CancelOrderReason reason,
    String note = '',
  }) async {
    if (state.isCancelling || _orderId.isEmpty) return false;
    safeEmit(state.copyWith(isCancelling: true));
    final result = await _cancelOrder(
      CancelOrderParams(
        CancelOrderRequest(orderId: _orderId, reason: reason, note: note),
      ),
    );
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isCancelling: false,
          failure: failure,
          failedAction: OrderTrackingAction.cancel,
        ),
      ),
      (order) => safeEmit(
        state.copyWith(isCancelling: false, order: order, cancelled: true),
      ),
    );
    _schedule();
    return result.isRight();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    _polling = false;
    return super.close();
  }
}
