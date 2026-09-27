import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';

class OrderInvoiceState extends Equatable
    implements ScreenLoadState<OrderInvoiceState> {
  const OrderInvoiceState({this.load = const ScreenLoad(), this.order});

  /// The order's read, its freshness and the failure that goes with them.
  @override
  final ScreenLoad load;
  final OrderEntity? order;

  bool get isLoaded => load.isLoaded;
  bool get isSignedOut => load.isSignedOut;

  /// The reason for the full-screen state; `null` while the invoice shows.
  Failure? get loadFailure => load.hasFailed ? load.failure : null;

  @override
  OrderInvoiceState withLoad(ScreenLoad load) => copyWith(load: load);

  OrderInvoiceState copyWith({ScreenLoad? load, OrderEntity? order}) =>
      OrderInvoiceState(
        load: load ?? this.load.settled(),
        order: order ?? this.order,
      );

  @override
  List<Object?> get props => [load, order];
}
