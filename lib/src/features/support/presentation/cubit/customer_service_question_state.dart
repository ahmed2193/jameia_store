import 'package:equatable/equatable.dart';

import '../../domain/entities/faq_item.dart';

enum CustomerServiceQuestionStatus { initial, loading, loaded, error }

/// State of `mach_pro_sailor_c_customer_service_question` — the FAQ list.
///
/// The search text and which item is open are transient view state kept in
/// the screen (a `TextEditingController` + `ValueNotifier`s).
class CustomerServiceQuestionState extends Equatable {
  const CustomerServiceQuestionState({
    this.status = CustomerServiceQuestionStatus.initial,
    this.faqs = const <FaqItem>[],
    this.errorMessage,
  });

  final CustomerServiceQuestionStatus status;
  final List<FaqItem> faqs;
  final String? errorMessage;

  CustomerServiceQuestionState copyWith({
    CustomerServiceQuestionStatus? status,
    List<FaqItem>? faqs,
    String? errorMessage,
  }) => CustomerServiceQuestionState(
    status: status ?? this.status,
    faqs: faqs ?? this.faqs,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [status, faqs, errorMessage];
}
