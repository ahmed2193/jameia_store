import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';

enum OrderTrackingStatus { initial, loading, loaded, error }

enum OrderTrackingAction { none, load, refresh, poll, cancel }

class OrderTrackingState extends Equatable {
  const OrderTrackingState({
    this.status = OrderTrackingStatus.initial,
    this.order,
    this.isRefreshing = false,
    this.isCancelling = false,
    this.cancelled = false,
    this.failure,
    this.failedAction = OrderTrackingAction.none,
  });

  final OrderTrackingStatus status;
  final OrderEntity? order;
  final bool isRefreshing;
  final bool isCancelling;

  /// Set on the state right after a successful cancel (one-shot toast).
  final bool cancelled;
  final Failure? failure;
  final OrderTrackingAction failedAction;

  Failure? get loadFailure =>
      status == OrderTrackingStatus.error &&
          failedAction == OrderTrackingAction.load
      ? failure
      : null;
  bool get isSignedOut => failure is UnauthorizedFailure;
  bool get isNotFound => failure is NotFoundFailure;
  bool get canCancel => order?.canCancel == true && !isCancelling;

  OrderTrackingState copyWith({
    OrderTrackingStatus? status,
    OrderEntity? order,
    bool? isRefreshing,
    bool? isCancelling,
    bool cancelled = false,
    Failure? failure,
    OrderTrackingAction? failedAction,
  }) => OrderTrackingState(
    status: status ?? this.status,
    order: order ?? this.order,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isCancelling: isCancelling ?? this.isCancelling,
    cancelled: cancelled,
    failure: failure,
    failedAction: failedAction ?? OrderTrackingAction.none,
  );

  @override
  List<Object?> get props => [
    status,
    order,
    isRefreshing,
    isCancelling,
    cancelled,
    failure,
    failedAction,
  ];
}
