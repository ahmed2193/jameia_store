import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/usecases/watch_order_usecase.dart';
import 'order_invoice_state.dart';

/// The invoice is the order's own totals — nothing is computed on the
/// device. The copy saved on the device shows at once (offline too), then
/// the server's; the screen flow is the loader mixins'.
class OrderInvoiceCubit extends Cubit<OrderInvoiceState>
    with
        SafeCubitMixin<OrderInvoiceState>,
        SnapshotLoaderMixin<OrderInvoiceState>,
        ScreenLoaderMixin<OrderInvoiceState> {
  OrderInvoiceCubit({required this._watchOrder})
    : super(const OrderInvoiceState());

  final WatchOrderUseCase _watchOrder;
  String _orderId = '';

  /// First load or retry: the loader only while nothing is on screen.
  Future<void> load(String orderId) {
    _orderId = orderId;
    showLoading();
    return _read(forceRefresh: false);
  }

  /// The server's invoice (the reconnect refresh of a saved one).
  @override
  Future<void> refresh() =>
      _orderId.isEmpty ? Future<void>.value() : _read(forceRefresh: true);

  Future<void> _read({required bool forceRefresh}) => readScreen<OrderEntity>(
    _watchOrder(WatchOrderParams(_orderId, forceRefresh: forceRefresh)),
    show: (state, snapshot) => state.copyWith(order: snapshot.data),
  );
}
