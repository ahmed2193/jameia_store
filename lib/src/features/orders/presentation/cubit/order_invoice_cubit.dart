import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

enum OrderInvoiceStatus { initial, loading, loaded, error }

/// Page state for the e-invoice / receipt screen. Resolves one [OrderEntity]
/// (by id, or the most recent order) through [OrdersRepository] and holds the
/// locally-chosen invoice title (the live app drives this through the
/// `CHOOSE_INVOICE_TITLE` host bridge).
class OrderInvoiceState extends Equatable {
  const OrderInvoiceState({
    this.status = OrderInvoiceStatus.initial,
    this.order,
    this.invoiceTitle = 'Personal',
    this.error,
  });

  final OrderInvoiceStatus status;
  final OrderEntity? order;
  final String invoiceTitle;
  final String? error;

  OrderInvoiceState copyWith({
    OrderInvoiceStatus? status,
    OrderEntity? order,
    String? invoiceTitle,
    String? error,
  }) => OrderInvoiceState(
    status: status ?? this.status,
    order: order ?? this.order,
    invoiceTitle: invoiceTitle ?? this.invoiceTitle,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, order, invoiceTitle, error];
}

/// Page-scoped cubit — resolved via `sl<OrderInvoiceCubit>()` and loaded with
/// `..load(orderId)`.
class OrderInvoiceCubit extends Cubit<OrderInvoiceState>
    with SafeCubitMixin<OrderInvoiceState> {
  OrderInvoiceCubit(this._repository) : super(const OrderInvoiceState());

  final OrdersRepository _repository;

  /// Loads [orderId] (or the most recent order when null/missing).
  Future<void> load(String? orderId) async {
    safeEmit(state.copyWith(status: OrderInvoiceStatus.loading));
    final result = await _repository.getInvoice(orderId);
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: OrderInvoiceStatus.error,
          error: failure.message,
        ),
      ),
      (order) => safeEmit(
        state.copyWith(status: OrderInvoiceStatus.loaded, order: order),
      ),
    );
  }

  /// Updates the chosen invoice title (kept local to the page).
  void chooseTitle(String title) {
    if (state.status == OrderInvoiceStatus.loaded) {
      safeEmit(state.copyWith(invoiceTitle: title));
    }
  }
}
