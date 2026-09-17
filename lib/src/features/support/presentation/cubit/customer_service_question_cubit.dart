import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/repositories/support_repository.dart';

enum CustomerServiceQuestionStatus { initial, loading, loaded, error }

/// State for `mach_pro_sailor_c_customer_service_question` — the FAQ list.
///
/// Search filtering + which item is expanded are transient view concerns handled
/// locally in the screen (`TextEditingController` + `ValueNotifier`s), so they
/// stay out of the cubit.
class CustomerServiceQuestionState extends Equatable {
  const CustomerServiceQuestionState({
    this.status = CustomerServiceQuestionStatus.initial,
    this.faqs = const [],
    this.error,
  });

  final CustomerServiceQuestionStatus status;
  final List<FaqItem> faqs;
  final String? error;

  CustomerServiceQuestionState copyWith({
    CustomerServiceQuestionStatus? status,
    List<FaqItem>? faqs,
    String? error,
  }) => CustomerServiceQuestionState(
    status: status ?? this.status,
    faqs: faqs ?? this.faqs,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, faqs, error];
}

/// Page-scoped cubit — resolved via `sl<CustomerServiceQuestionCubit>()`; loads
/// the FAQ list on construction through the [SupportRepository].
class CustomerServiceQuestionCubit extends Cubit<CustomerServiceQuestionState>
    with SafeCubitMixin<CustomerServiceQuestionState> {
  CustomerServiceQuestionCubit(this._repository)
    : super(const CustomerServiceQuestionState()) {
    load();
  }

  final SupportRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: CustomerServiceQuestionStatus.loading));
    final result = await _repository.getFaqs();
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: CustomerServiceQuestionStatus.error,
          error: failure.message,
        ),
      ),
      (faqs) => safeEmit(
        state.copyWith(
          status: CustomerServiceQuestionStatus.loaded,
          faqs: faqs,
        ),
      ),
    );
  }
}
