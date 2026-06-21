import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Refund-reason options (KeeTa `refundpage_refundreason_*`).
enum RefundReason {
  missingItem('Missing item'),
  wrongItem('Wrong item'),
  qualityIssue('Quality issue'),
  lateDelivery('Late delivery'),
  other('Other');

  const RefundReason(this.label);
  final String label;
}

/// Refund-request form state. One bundle (`v1/order/refund`) — reason radio,
/// per-item selected quantities, description text, photo evidence count, and the
/// derived refund amount. Submit validity is `canSubmit`.
class OrderRefundState extends Equatable {
  final KeetaOrder order;

  /// Selected refund reason (null until the user picks one).
  final RefundReason? reason;

  /// Refund quantity chosen per item index (0 = not refunding that item).
  final Map<int, int> selectedQty;

  /// Free-text problem description.
  final String description;

  /// Dummy photo-evidence tiles (just a count for the clone).
  final int photoCount;

  const OrderRefundState({
    required this.order,
    this.reason,
    this.selectedQty = const {},
    this.description = '',
    this.photoCount = 0,
  });

  /// Sum of (selected qty × unit price) across all items.
  double get refundAmount {
    var total = 0.0;
    for (final entry in selectedQty.entries) {
      total += order.items[entry.key].price * entry.value;
    }
    return total;
  }

  int get selectedItemCount =>
      selectedQty.values.fold(0, (s, q) => s + (q > 0 ? 1 : 0));

  /// Need a reason AND at least one item quantity selected.
  bool get canSubmit =>
      reason != null && selectedQty.values.any((q) => q > 0);

  OrderRefundState copyWith({
    RefundReason? reason,
    Map<int, int>? selectedQty,
    String? description,
    int? photoCount,
  }) =>
      OrderRefundState(
        order: order,
        reason: reason ?? this.reason,
        selectedQty: selectedQty ?? this.selectedQty,
        description: description ?? this.description,
        photoCount: photoCount ?? this.photoCount,
      );

  @override
  List<Object?> get props =>
      [order, reason, selectedQty, description, photoCount];
}

/// Page-scoped cubit driving the refund-request form. Constructed inline via
/// `BlocProvider(create: (_) => OrderRefundCubit(sl<KeetaRepository>()))`.
class OrderRefundCubit extends Cubit<OrderRefundState> {
  OrderRefundCubit(KeetaRepository repo)
      : super(OrderRefundState(order: repo.orders.first));

  void selectReason(RefundReason reason) =>
      emit(state.copyWith(reason: reason));

  void increment(int index) {
    final max = state.order.items[index].qty;
    final current = state.selectedQty[index] ?? 0;
    if (current >= max) return;
    emit(state.copyWith(
        selectedQty: {...state.selectedQty, index: current + 1}));
  }

  void decrement(int index) {
    final current = state.selectedQty[index] ?? 0;
    if (current <= 0) return;
    emit(state.copyWith(
        selectedQty: {...state.selectedQty, index: current - 1}));
  }

  void setDescription(String value) =>
      emit(state.copyWith(description: value));

  void addPhoto() => emit(state.copyWith(photoCount: state.photoCount + 1));

  void removePhoto(int index) {
    if (state.photoCount <= 0) return;
    emit(state.copyWith(photoCount: state.photoCount - 1));
  }
}
