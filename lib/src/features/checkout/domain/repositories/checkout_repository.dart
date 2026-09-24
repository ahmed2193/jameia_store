import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../entities/branch_entity.dart';
import '../entities/checkout_draft.dart';
import '../entities/delivery_selection_entity.dart';
import '../entities/delivery_slot_entity.dart';

/// Delivery choices and order placement (`/v1/delivery/*`, `POST /v1/orders`).
abstract class CheckoutRepository {
  /// Branches the customer may pick up from; cached for the session.
  Future<Either<Failure, List<BranchEntity>>> getBranches();

  /// Bookable delivery windows, fresh every call (capacity moves).
  Future<Either<Failure, List<DeliverySlotDayEntity>>> getDeliverySlots();

  /// Deliver to a saved address; the server re-prices the cart.
  Future<Either<Failure, DeliverySelectionEntity>> selectDeliveryAddress(
    String addressId,
  );

  /// Pick up from a branch; the server re-prices the cart.
  Future<Either<Failure, DeliverySelectionEntity>> selectPickupBranch(
    String branchId,
  );

  /// Turns the server cart into an order.
  Future<Either<Failure, OrderEntity>> placeOrder(CheckoutDraft draft);
}
