import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_faqs_usecase.dart';
import 'customer_service_question_state.dart';

export 'customer_service_question_state.dart';

/// Page-scoped cubit of the FAQ topics page; the page calls [load].
class CustomerServiceQuestionCubit extends Cubit<CustomerServiceQuestionState>
    with SafeCubitMixin<CustomerServiceQuestionState> {
  CustomerServiceQuestionCubit(this._getFaqs)
    : super(const CustomerServiceQuestionState());

  final GetFaqsUseCase _getFaqs;

  Future<void> load() async {
    safeEmit(state.copyWith(status: CustomerServiceQuestionStatus.loading));
    final result = await _getFaqs(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: CustomerServiceQuestionStatus.error,
          errorMessage: failure.message,
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
