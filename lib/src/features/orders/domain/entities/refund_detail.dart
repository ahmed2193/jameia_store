import 'package:equatable/equatable.dart';

/// View-model for one refund (`mach_pro_sailor_c_order_refund_detail`).
///
/// [JameiaOrder] carries no refund fields, so the amounts / method / stage are
/// derived (in the data layer) from the order total with fixed demo deductions.
class RefundDetail extends Equatable {
  const RefundDetail({
    required this.orderId,
    required this.shopName,
    required this.stage,
    required this.etaLabel,
    required this.itemRefund,
    required this.deliveryRefund,
    required this.voucherDeduction,
    required this.method,
  });

  /// Total number of refund stages (submitted → processing → approved →
  /// refunded). Kept in sync with the screen's `_kRefundStages` list length.
  static const int stageCount = 4;

  final String orderId;
  final String shopName;

  /// Completed stages, 1..[stageCount] (the current active stage equals this).
  final int stage;
  final String etaLabel;
  final double itemRefund;
  final double deliveryRefund;
  final double voucherDeduction;
  final String method;

  double get totalRefund => itemRefund + deliveryRefund - voucherDeduction;

  @override
  List<Object?> get props => [
    orderId,
    shopName,
    stage,
    etaLabel,
    itemRefund,
    deliveryRefund,
    voucherDeduction,
    method,
  ];
}
