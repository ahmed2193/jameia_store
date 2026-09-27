import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/usecase/watch_params.dart';
import '../entities/orders_page.dart';
import '../repositories/orders_repository.dart';
import 'get_orders_usecase.dart';

/// The first page of the customer's orders (newest first), as long as
/// [GetOrdersUseCase]'s pages: the copy saved on the device first, then the
/// server's; failures on the error channel. The next pages are
/// [GetOrdersUseCase]'s — never kept.
class WatchOrdersUseCase
    implements StreamUseCase<DataSnapshot<OrdersPage>, WatchParams> {
  const WatchOrdersUseCase(this._repository);

  final OrdersRepository _repository;

  @override
  Stream<DataSnapshot<OrdersPage>> call(WatchParams params) =>
      _repository.watchFirstPage(
        limit: GetOrdersParams.defaultLimit,
        forceRefresh: params.forceRefresh,
      );
}
