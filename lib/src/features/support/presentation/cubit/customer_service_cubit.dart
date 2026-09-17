import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/jameia_order_entity.dart';
import '../../domain/repositories/support_repository.dart';

enum CustomerServiceStatus { initial, loading, loaded, error }

/// State for the customer-service help-center hub
/// (`mach_pro_sailor_c_customer_service`) — recent-order card + scripted FAQ
/// topics, loaded through the [SupportRepository].
class CustomerServiceState extends Equatable {
  const CustomerServiceState({
    this.status = CustomerServiceStatus.initial,
    this.recentOrder,
    this.faqs = const [],
    this.error,
  });

  final CustomerServiceStatus status;

  /// Newest order shown in the "Get help with this order" card. Null when none.
  final JameiaOrderEntity? recentOrder;

  /// FAQ topics rendered as a chevron list → `customer_service_question`.
  final List<String> faqs;
  final String? error;

  CustomerServiceState copyWith({
    CustomerServiceStatus? status,
    JameiaOrderEntity? recentOrder,
    List<String>? faqs,
    String? error,
  }) => CustomerServiceState(
    status: status ?? this.status,
    recentOrder: recentOrder ?? this.recentOrder,
    faqs: faqs ?? this.faqs,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, recentOrder, faqs, error];
}

/// Page-scoped cubit — resolved via `sl<CustomerServiceCubit>()`; loads the hub
/// on construction.
class CustomerServiceCubit extends Cubit<CustomerServiceState>
    with SafeCubitMixin<CustomerServiceState> {
  CustomerServiceCubit(this._repository) : super(const CustomerServiceState()) {
    load();
  }

  final SupportRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: CustomerServiceStatus.loading));
    final result = await _repository.getSupportHub();
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: CustomerServiceStatus.error,
          error: failure.message,
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
