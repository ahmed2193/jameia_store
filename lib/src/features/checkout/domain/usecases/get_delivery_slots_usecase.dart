import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/delivery_slot_entity.dart';
import '../repositories/checkout_repository.dart';

/// Days that still have a bookable window.
class GetDeliverySlotsUseCase
    implements UseCase<List<DeliverySlotDayEntity>, NoParams> {
  const GetDeliverySlotsUseCase(this._repository);
  final CheckoutRepository _repository;

  @override
  Future<Either<Failure, List<DeliverySlotDayEntity>>> call(
    NoParams params,
  ) async => (await _repository.getDeliverySlots()).map(
    (days) => [
      for (final day in days)
        if (day.hasBookableSlot) day,
    ],
  );
}
