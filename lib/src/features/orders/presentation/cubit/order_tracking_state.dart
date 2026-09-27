import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';

class OrderTrackingState extends Equatable
    implements ScreenLoadState<OrderTrackingState> {
  const OrderTrackingState({
    this.load = const ScreenLoad(),
    this.order,
    this.isRefreshing = false,
    this.isCancelling = false,
    this.cancelled = false,
  });

  /// The order's read, how fresh it is (the device copy, a failed poll … —
  /// behind the "Last known status" note) and the failure that goes with
  /// them (a failed cancel is told as the customer's action).
  @override
  final ScreenLoad load;
  final OrderEntity? order;
  final bool isRefreshing;
  final bool isCancelling;

  /// Set on the state right after a successful cancel (one-shot toast).
  final bool cancelled;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;

  /// The reason there is nothing to show; `null` once there is an order.
  Failure? get loadFailure => load.hasFailed ? load.failure : null;
  bool get isSignedOut => load.isSignedOut;
  bool get isNotFound => loadFailure is NotFoundFailure;
  bool get canCancel => order?.canCancel == true && !isCancelling;

  @override
  OrderTrackingState withLoad(ScreenLoad load) => copyWith(load: load);

  OrderTrackingState copyWith({
    ScreenLoad? load,
    OrderEntity? order,
    bool? isRefreshing,
    bool? isCancelling,
    bool cancelled = false,
  }) => OrderTrackingState(
    load: load ?? this.load.settled(),
    order: order ?? this.order,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isCancelling: isCancelling ?? this.isCancelling,
    cancelled: cancelled,
  );

  @override
  List<Object?> get props => [
    load,
    order,
    isRefreshing,
    isCancelling,
    cancelled,
  ];
}
