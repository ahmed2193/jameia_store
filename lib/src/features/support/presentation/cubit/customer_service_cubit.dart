import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_support_hub_usecase.dart';
import 'customer_service_state.dart';

export 'customer_service_state.dart';

/// Page-scoped cubit of the help-center hub; the page calls [load].
class CustomerServiceCubit extends Cubit<CustomerServiceState>
    with SafeCubitMixin<CustomerServiceState> {
  CustomerServiceCubit(this._getSupportHub)
    : super(const CustomerServiceState());

  final GetSupportHubUseCase _getSupportHub;

  Future<void> load() async {
    safeEmit(state.copyWith(status: CustomerServiceStatus.loading));
    final result = await _getSupportHub(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: CustomerServiceStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (hub) => safeEmit(
        state.copyWith(
          status: CustomerServiceStatus.loaded,
          recentOrder: hub.recentOrder,
          faqs: hub.faqTopics,
        ),
      ),
    );
  }
}
