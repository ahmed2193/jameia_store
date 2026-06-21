import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Page-scoped state for the order-tracking screen. Resolves one [KeetaOrder] by
/// id plus the user's default delivery address from the dummy [KeetaRepository].
sealed class OrderTrackingState extends Equatable {
  const OrderTrackingState();
  @override
  List<Object?> get props => [];
}

class OrderTrackingLoading extends OrderTrackingState {
  const OrderTrackingLoading();
}

class OrderTrackingError extends OrderTrackingState {
  const OrderTrackingError();
}

class OrderTrackingLoaded extends OrderTrackingState {
  const OrderTrackingLoaded({required this.order, required this.address});
  final KeetaOrder order;
  final KeetaAddress address;
  @override
  List<Object?> get props => [order, address];
}

/// Page cubit — construct inline with `BlocProvider(create: ...)`, never
/// registered in the service locator (per the project's page-cubit convention).
class OrderTrackingCubit extends Cubit<OrderTrackingState> {
  OrderTrackingCubit(this._repo) : super(const OrderTrackingLoading());

  final KeetaRepository _repo;

  void load(String orderId) {
    try {
      final order = _repo.orderById(orderId);
      emit(OrderTrackingLoaded(order: order, address: _repo.defaultAddress));
    } catch (_) {
      emit(const OrderTrackingError());
    }
  }
}
