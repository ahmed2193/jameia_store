import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/order_status.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/cancel_order_request.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/watch_order_usecase.dart';
import 'order_tracking_state.dart';

/// One order's live status. The copy saved on the device shows at once
/// (offline too); then it polls `GET /v1/orders/{id}` every [pollInterval]
/// while the page is visible, the app is online and the order can still
/// move — no poll is scheduled offline, and the connection coming back polls
/// once right away. Stops on a terminal status, when the page hides, and on
/// close. Cancel runs once.
class OrderTrackingCubit extends Cubit<OrderTrackingState>
    with
        SafeCubitMixin<OrderTrackingState>,
        SnapshotLoaderMixin<OrderTrackingState> {
  OrderTrackingCubit({
    required this._watchOrder,
    required this._cancelOrder,
    this.pollInterval = defaultPollInterval,
  }) : super(const OrderTrackingState());

  /// The backend asks for at least 30 s between polls.
  static const Duration defaultPollInterval = Duration(seconds: 30);

  final WatchOrderUseCase _watchOrder;
  final CancelOrderUseCase _cancelOrder;
  final Duration pollInterval;

  String _orderId = '';
  bool _visible = true;
  bool _offline = false;
  bool _polling = false;
  Timer? _timer;
  int _generation = 0;

  /// Whether this cubit is keeping the order up to date — true across the
  /// gap where a poll is in flight and no timer is armed yet, which is what
  /// the page (and a test) means by "still polling".
  bool get isPolling => _polling;

  Future<void> load(String orderId) {
    _orderId = orderId;
    safeEmit(state.withLoad(state.load.started()));
    return _read(forceRefresh: false);
  }

  Future<void> refresh() async {
    if (state.isRefreshing || _orderId.isEmpty) return;
    safeEmit(state.copyWith(isRefreshing: true));
    await _read(forceRefresh: true);
  }

  /// The page tells the cubit when it is on screen; polling follows.
  void setVisible(bool visible) {
    _visible = visible;
    _schedule();
  }

  /// The page tells the cubit when the app goes offline: no poll is
  /// scheduled then (it could only fail).
  void setOffline(bool offline) {
    if (_offline == offline) return;
    _offline = offline;
    _schedule();
  }

  /// The connection came back: an order that can still move is polled once
  /// right away; a saved copy or a page that could not load asks again.
  Future<void> onReconnected() {
    bool needed() {
      final order = state.order;
      return _orderId.isNotEmpty &&
          (state.load.needsRefresh || (order != null && !order.isTerminal));
    }

    return refreshOnReconnect(
      needed: needed,
      refresh: () => _read(forceRefresh: true, poll: state.order != null),
    );
  }

  /// [poll]: nobody asked for this read (the timer, the reconnect over an
  /// order on screen).
  Future<void> _read({required bool forceRefresh, bool poll = false}) async {
    final generation = ++_generation;
    await followSnapshots<OrderEntity>(
      _watchOrder(WatchOrderParams(_orderId, forceRefresh: forceRefresh)),
      onSnapshot: (snapshot) => safeEmit(
        state.copyWith(
          load: state.load.arrived(snapshot),
          order: snapshot.data,
          isRefreshing: false,
        ),
      ),
      onFailure: (failure) => _onReadFailed(failure, poll: poll),
      showsData: () => state.order != null,
    );
    if (generation == _generation) _schedule();
  }

  void _onReadFailed(Failure failure, {required bool poll}) {
    if (poll && state.order != null) {
      // Nobody asked for this request: keep the order on screen — now its
      // last known status — and try again on the next tick instead of
      // raising a toast every interval.
      safeEmit(state.withLoad(state.load.failedQuietly()));
      return;
    }
    safeEmit(
      state.copyWith(isRefreshing: false, load: state.load.failedWith(failure)),
    );
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final order = state.order;
    _polling =
        _visible &&
        !_offline &&
        order != null &&
        !order.isTerminal &&
        !isClosed;
    if (!_polling) return;
    _timer = Timer(pollInterval, () {
      _timer = null;
      if (!isClosed) {
        unawaited(_read(forceRefresh: true, poll: true));
      }
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
        state.copyWith(isCancelling: false, load: state.load.noted(failure)),
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
