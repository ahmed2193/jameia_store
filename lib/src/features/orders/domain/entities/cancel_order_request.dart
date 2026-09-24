import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_status.dart';

/// `POST /v1/orders/{orderId}/cancel`.
class CancelOrderRequest extends Equatable {
  const CancelOrderRequest({
    required this.orderId,
    required this.reason,
    this.note = '',
  });

  static const int maxNoteLength = 256;

  final String orderId;
  final CancelOrderReason reason;
  final String note;

  bool get isValid => orderId.isNotEmpty && note.length <= maxNoteLength;

  @override
  List<Object?> get props => [orderId, reason, note];
}
