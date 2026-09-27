import 'package:equatable/equatable.dart';

import '../../domain/entities/faq_item.dart';
import '../../domain/entities/support_order.dart';

enum CustomerServiceStatus { initial, loading, loaded, error }

/// State of the customer-service help-center hub
/// (`mach_pro_sailor_c_customer_service`): the recent-order card and the FAQ
/// topics.
class CustomerServiceState extends Equatable {
  const CustomerServiceState({
    this.status = CustomerServiceStatus.initial,
    this.recentOrder,
    this.faqs = const <FaqItem>[],
    this.errorMessage,
  });

  final CustomerServiceStatus status;

  /// Newest order shown in the "Get help with this order" card. Null when none.
  final SupportOrder? recentOrder;

  /// FAQ topics rendered as a chevron list → `customer_service_question`.
  final List<FaqItem> faqs;
  final String? errorMessage;

  CustomerServiceState copyWith({
    CustomerServiceStatus? status,
    SupportOrder? recentOrder,
    List<FaqItem>? faqs,
    String? errorMessage,
  }) => CustomerServiceState(
    status: status ?? this.status,
    recentOrder: recentOrder ?? this.recentOrder,
    faqs: faqs ?? this.faqs,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, recentOrder, faqs, errorMessage];
}
