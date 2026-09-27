import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/orders_repository.dart';

class WatchOrderParams extends Equatable {
  const WatchOrderParams(this.orderId, {this.forceRefresh = false});

  final String orderId;

  /// A poll, a retry or a reconnect: the server's, now.
  final bool forceRefresh;

  @override
  List<Object?> get props => [orderId, forceRefresh];
}

/// One order (`GET /v1/orders/{id}`) for tracking, the invoice and the
/// review: the copy saved on the device first (offline too), then the
/// server's — always asked, an order moves; failures on the error channel.
class WatchOrderUseCase
    implements StreamUseCase<DataSnapshot<OrderEntity>, WatchOrderParams> {
  const WatchOrderUseCase(this._repository);

  final OrdersRepository _repository;

  @override
  Stream<DataSnapshot<OrderEntity>> call(WatchOrderParams params) {
    if (params.orderId.isEmpty) {
      return Stream.error(const ValidationFailure('order id'));
    }
    return _repository.watchOrder(
      params.orderId,
      forceRefresh: params.forceRefresh,
    );
  }
}
