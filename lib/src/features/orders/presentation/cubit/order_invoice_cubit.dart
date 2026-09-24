import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_order_usecase.dart';
import 'order_invoice_state.dart';

/// The invoice is the order's own totals — nothing is computed on the
/// device.
class OrderInvoiceCubit extends Cubit<OrderInvoiceState>
    with SafeCubitMixin<OrderInvoiceState> {
  OrderInvoiceCubit({required this._getOrder})
    : super(const OrderInvoiceState());

  final GetOrderUseCase _getOrder;

  Future<void> load(String orderId) async {
    safeEmit(state.copyWith(status: OrderInvoiceStatus.loading));
    final result = await _getOrder(GetOrderParams(orderId));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: OrderInvoiceStatus.error, failure: failure),
      ),
      (order) => safeEmit(
        state.copyWith(status: OrderInvoiceStatus.loaded, order: order),
      ),
    );
  }
}
