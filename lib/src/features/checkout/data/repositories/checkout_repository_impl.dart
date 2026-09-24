import 'package:dartz/dartz.dart';

import '../../../../core/data/mappers/order_mapper.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/delivery_selection_entity.dart';
import '../../domain/entities/delivery_slot_entity.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_remote_data_source.dart';
import '../datasources/delivery_remote_data_source.dart';
import '../mappers/checkout_mapper.dart';

class CheckoutRepositoryImpl
    with BaseRepositoryMixin
    implements CheckoutRepository {
  const CheckoutRepositoryImpl(this._delivery, this._checkout);

  final DeliveryRemoteDataSource _delivery;
  final CheckoutRemoteDataSource _checkout;

  @override
  Future<Either<Failure, List<BranchEntity>>> getBranches() =>
      execute(() async => (await _delivery.getBranches()).toEntities());

  @override
  Future<Either<Failure, List<DeliverySlotDayEntity>>> getDeliverySlots() =>
      execute(() async => (await _delivery.getSlots()).toEntities());

  @override
  Future<Either<Failure, DeliverySelectionEntity>> selectDeliveryAddress(
    String addressId,
  ) => execute(
    () async => (await _delivery.selectAddress(addressId)).toEntity(),
  );

  @override
  Future<Either<Failure, DeliverySelectionEntity>> selectPickupBranch(
    String branchId,
  ) => execute(() async => (await _delivery.selectBranch(branchId)).toEntity());

  @override
  Future<Either<Failure, OrderEntity>> placeOrder(CheckoutDraft draft) =>
      execute(
        () async => (await _checkout.placeOrder(draft.toBody())).toEntity(),
      );
}
