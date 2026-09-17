import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

/// Refund-reason options (Jameia `refundpage_refundreason_*`).
enum RefundReason {
  missingItem('Missing item'),
  wrongItem('Wrong item'),
  qualityIssue('Quality issue'),
  lateDelivery('Late delivery'),
  other('Other');

  const RefundReason(this.label);
  final String label;
}

enum OrderRefundStatus { initial, loading, loaded, error }

/// Refund-request form state. One bundle (`v1/order/refund`) — reason radio,
/// per-item selected quantities, description text, photo evidence count, and the
/// derived refund amount. The target order is loaded through [OrdersRepository];
/// submit validity is [canSubmit].
class OrderRefundState extends Equatable {
  const OrderRefundState({
    this.status = OrderRefundStatus.initial,
    this.order,
    this.reason,
    this.selectedQty = const {},
    this.description = '',
    this.photoCount = 0,
    this.error,
  });

  final OrderRefundStatus status;

  /// The order being refunded (null until loaded).
  final OrderEntity? order;

  /// Selected refund reason (null until the user picks one).
  final RefundReason? reason;

  /// Refund quantity chosen per item index (0 = not refunding that item).
  final Map<int, int> selectedQty;

  /// Free-text problem description.
  final String description;

  /// Dummy photo-evidence tiles (just a count for the clone).
  final int photoCount;

  final String? error;

  /// Sum of (selected qty × unit price) across all items.
  double get refundAmount {
    final o = order;
    if (o == null) return 0;
    var total = 0.0;
    for (final entry in selectedQty.entries) {
      total += o.items[entry.key].price * entry.value;
    }
    return total;
  }

  int get selectedItemCount =>
      selectedQty.values.fold(0, (s, q) => s + (q > 0 ? 1 : 0));

  /// Need a loaded order, a reason AND at least one item quantity selected.
  bool get canSubmit =>
      order != null && reason != null && selectedQty.values.any((q) => q > 0);

  OrderRefundState copyWith({
    OrderRefundStatus? status,
    OrderEntity? order,
    RefundReason? reason,
    Map<int, int>? selectedQty,
    String? description,
    int? photoCount,
    String? error,
  }) => OrderRefundState(
    status: status ?? this.status,
    order: order ?? this.order,
    reason: reason ?? this.reason,
    selectedQty: selectedQty ?? this.selectedQty,
    description: description ?? this.description,
    photoCount: photoCount ?? this.photoCount,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [
    status,
    order,
    reason,
    selectedQty,
    description,
    photoCount,
    error,
  ];
}

/// Page-scoped cubit driving the refund-request form — resolved via
/// `sl<OrderRefundCubit>()`; loads the target order on construction.
class OrderRefundCubit extends Cubit<OrderRefundState>
    with SafeCubitMixin<OrderRefundState> {
  OrderRefundCubit(this._repository) : super(const OrderRefundState()) {
    load();
  }

  final OrdersRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: OrderRefundStatus.loading));
    final result = await _repository.getRefundFormOrder();
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: OrderRefundStatus.error, error: failure.message),
      ),
      (order) => safeEmit(
        state.copyWith(status: OrderRefundStatus.loaded, order: order),
      ),
    );
  }

  void selectReason(RefundReason reason) =>
      safeEmit(state.copyWith(reason: reason));

  void increment(int index) {
    final order = state.order;
    if (order == null) return;
    final max = order.items[index].qty;
    final current = state.selectedQty[index] ?? 0;
    if (current >= max) return;
    safeEmit(
      state.copyWith(selectedQty: {...state.selectedQty, index: current + 1}),
    );
  }

  void decrement(int index) {
    final current = state.selectedQty[index] ?? 0;
    if (current <= 0) return;
    safeEmit(
      state.copyWith(selectedQty: {...state.selectedQty, index: current - 1}),
    );
  }

  void setDescription(String value) =>
      safeEmit(state.copyWith(description: value));

  void addPhoto() => safeEmit(state.copyWith(photoCount: state.photoCount + 1));

  void removePhoto(int index) {
    if (state.photoCount <= 0) return;
    safeEmit(state.copyWith(photoCount: state.photoCount - 1));
  }

  /// Submit the refund request (offline: accepted no-op). Fired as the success
  /// dialog is shown; the result does not gate the UI.
  Future<void> submit() async {
    final order = state.order;
    if (order == null || !state.canSubmit) return;
    await _repository.submitRefund(
      orderId: order.id,
      reason: state.reason?.label,
      selectedQty: state.selectedQty,
      description: state.description,
      photoCount: state.photoCount,
      amount: state.refundAmount,
    );
  }
}
