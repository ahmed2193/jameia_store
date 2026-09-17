import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_address.dart';
import '../../domain/repositories/orders_repository.dart';

enum OrderTrackingStatus { initial, loading, loaded, error }

/// Page state for the order-tracking + order-map screens. Resolves one
/// [OrderEntity] plus the user's default delivery [OrderAddressEntity] through
/// [OrdersRepository]; a local timer then simulates live progress.
class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.status = OrderTrackingStatus.initial,
    this.order,
    this.address,
    this.error,
  });

  final OrderTrackingStatus status;
  final OrderEntity? order;
  final OrderAddressEntity? address;
  final String? error;

  OrderTrackingState copyWith({
    OrderTrackingStatus? status,
    OrderEntity? order,
    OrderAddressEntity? address,
    String? error,
  }) => OrderTrackingState(
    status: status ?? this.status,
    order: order ?? this.order,
    address: address ?? this.address,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, order, address, error];
}

/// Page-scoped cubit — resolved via `sl<OrderTrackingCubit>()` (the tracking
/// screen and the map screen each resolve their own instance) and loaded with
/// `..load(orderId)`.
class OrderTrackingCubit extends Cubit<OrderTrackingState>
    with SafeCubitMixin<OrderTrackingState> {
  OrderTrackingCubit(this._repository) : super(const OrderTrackingState());

  final OrdersRepository _repository;
  Timer? _timer;

  Future<void> load(String orderId) async {
    safeEmit(state.copyWith(status: OrderTrackingStatus.loading));
    final result = await _repository.getOrderTracking(orderId);
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: OrderTrackingStatus.error,
          error: failure.message,
        ),
      ),
      (view) {
        safeEmit(
          state.copyWith(
            status: OrderTrackingStatus.loaded,
            order: view.order,
            address: view.address,
          ),
        );
        _startSimulation();
      },
    );
  }

  /// Simulated live tracking — advances the progress stepper while the order is
  /// active (offline stand-in for `v1/order/status` polling).
  void _startSimulation() {
    _timer?.cancel();
    final order = state.order;
    if (state.status != OrderTrackingStatus.loaded ||
        order == null ||
        !order.isActive) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _tick());
  }

  void _tick() {
    final order = state.order;
    if (state.status != OrderTrackingStatus.loaded || order == null) {
      _timer?.cancel();
      return;
    }
    final step = order.statusStep;
    if (step >= 5) {
      _timer?.cancel();
      return;
    }
    final next = step + 1;
    safeEmit(
      state.copyWith(
        order: order.copyWith(
          statusStep: next,
          status: next >= 5 ? 'completed' : order.status,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
