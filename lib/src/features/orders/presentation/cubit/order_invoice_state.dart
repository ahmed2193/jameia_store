import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';

enum OrderInvoiceStatus { initial, loading, loaded, error }

class OrderInvoiceState extends Equatable {
  const OrderInvoiceState({
    this.status = OrderInvoiceStatus.initial,
    this.order,
    this.failure,
  });

  final OrderInvoiceStatus status;
  final OrderEntity? order;
  final Failure? failure;

  bool get isSignedOut => failure is UnauthorizedFailure;

  OrderInvoiceState copyWith({
    OrderInvoiceStatus? status,
    OrderEntity? order,
    Failure? failure,
  }) => OrderInvoiceState(
    status: status ?? this.status,
    order: order ?? this.order,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, order, failure];
}
