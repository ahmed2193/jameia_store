import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

enum OrdersStatus { initial, loading, loaded, error }

/// State for the orders list (`mach_pro_sailor_c_order_list`) — the two tabs
/// (In progress / History) resolved through [OrdersRepository]. The active /
/// history bucketing that used to live inline in the screen's `build` now
/// arrives pre-split via `OrdersView`.
class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.initial,
    this.active = const [],
    this.history = const [],
    this.error,
  });

  final OrdersStatus status;
  final List<OrderEntity> active;
  final List<OrderEntity> history;
  final String? error;

  OrdersState copyWith({
    OrdersStatus? status,
    List<OrderEntity>? active,
    List<OrderEntity>? history,
    String? error,
  }) => OrdersState(
    status: status ?? this.status,
    active: active ?? this.active,
    history: history ?? this.history,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, active, history, error];
}

/// Page-scoped cubit — resolved via `sl<OrdersCubit>()`; loads the order list on
/// construction and exposes [cancel] (wired to [OrdersRepository.cancelOrder]).
class OrdersCubit extends Cubit<OrdersState> with SafeCubitMixin<OrdersState> {
  OrdersCubit(this._repository) : super(const OrdersState()) {
    load();
  }

  final OrdersRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: OrdersStatus.loading));
    final result = await _repository.getOrders();
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: OrdersStatus.error, error: failure.message),
      ),
      (view) => safeEmit(
        state.copyWith(
          status: OrdersStatus.loaded,
          active: view.active,
          history: view.history,
        ),
      ),
    );
  }

  /// Cancel [orderId] (optionally with the chosen [reason]) then refresh the
  /// list so any local status change is reflected. Offline the catalogue has no
  /// cancel mutation, so the reload returns the same list (sheet just closes).
  Future<void> cancel(String orderId, {String? reason}) async {
    final result = await _repository.cancelOrder(
      orderId: orderId,
      reason: reason,
    );
    result.fold((_) {}, (_) => load());
  }
}
