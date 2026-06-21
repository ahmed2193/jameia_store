import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// State for the customer-service help-center hub
/// (`mach_pro_sailor_c_customer_service`).
///
/// Holds the most-recent order (drives the order-scoped help card) and the
/// scripted FAQ list. The real KeeTa page sources these from `/api/order` +
/// `/api/faq/faqList`; here they come from the in-memory [KeetaRepository] plus
/// a static FAQ script (KeeTa ships the same fixed help topics).
class CustomerServiceState {
  const CustomerServiceState({required this.recentOrder, required this.faqs});

  /// Newest order (`order_default`) shown in the "Get help with this order"
  /// card. Null when the user has no orders.
  final KeetaOrder? recentOrder;

  /// FAQ topics rendered as a chevron list → `customer_service_question`.
  final List<String> faqs;
}

/// Page-scoped cubit — constructed inline via
/// `BlocProvider(create: (_) => CustomerServiceCubit(sl<KeetaRepository>()))`.
/// Not registered in the service locator.
class CustomerServiceCubit extends Cubit<CustomerServiceState> {
  CustomerServiceCubit(KeetaRepository repo)
      : super(CustomerServiceState(
          recentOrder: repo.orders.isEmpty ? null : repo.orders.first,
          faqs: _faqTopics,
        ));

  /// Scripted FAQ help topics (KeeTa's fixed help-center questions).
  static const List<String> _faqTopics = [
    'Where is my order?',
    'How do I request a refund?',
    'My order is missing items',
    'How do I change my delivery address?',
    'How do I cancel an order?',
    'Payment & coupon questions',
  ];
}
