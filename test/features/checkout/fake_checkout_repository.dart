import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/data/mappers/order_mapper.dart';
import 'package:jameia_mart/src/core/data/models/order_model.dart';
import 'package:jameia_mart/src/core/domain/entities/cart_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/order_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/branch_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/checkout_draft.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/delivery_selection_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/entities/delivery_slot_entity.dart';
import 'package:jameia_mart/src/features/checkout/domain/repositories/checkout_repository.dart';

import '../orders/order_test_fixtures.dart';

/// Scripted checkout repository: records the calls, can hold a selection or
/// the order open, and can fail any of them once.
class FakeCheckoutRepository implements CheckoutRepository {
  final List<String> calls = <String>[];

  /// When set, the next branches read waits on it (a load in flight).
  Completer<void>? loadGate;

  Completer<void>? selectGate;
  Completer<void>? placeGate;

  Failure? branchesFailure;
  Failure? slotsFailure;
  Failure? selectFailure;
  Failure? placeFailure;

  List<BranchEntity> branches = const <BranchEntity>[
    BranchEntity(id: 'b1', name: 'Salmiya', supportsPickup: true),
    BranchEntity(id: 'b2', name: 'Warehouse', supportsPickup: false),
  ];

  List<DeliverySlotDayEntity> days = const <DeliverySlotDayEntity>[
    DeliverySlotDayEntity(
      date: '2026-09-22',
      label: 'Tomorrow',
      slots: <DeliverySlotEntity>[
        DeliverySlotEntity(
          templateId: 't1',
          date: '2026-09-22',
          label: '10:00 – 12:00',
          remaining: 2,
          available: true,
        ),
      ],
    ),
  ];

  @override
  Future<Either<Failure, List<BranchEntity>>> getBranches() async {
    calls.add('branches');
    final gate = loadGate;
    if (gate != null) {
      loadGate = null;
      await gate.future;
    }
    final failure = branchesFailure;
    branchesFailure = null;
    return failure == null ? Right(branches) : Left(failure);
  }

  @override
  Future<Either<Failure, List<DeliverySlotDayEntity>>>
  getDeliverySlots() async {
    calls.add('slots');
    final failure = slotsFailure;
    slotsFailure = null;
    return failure == null ? Right(days) : Left(failure);
  }

  @override
  Future<Either<Failure, DeliverySelectionEntity>> selectDeliveryAddress(
    String addressId,
  ) => _select('address:$addressId', FulfillmentMode.delivery, addressId);

  @override
  Future<Either<Failure, DeliverySelectionEntity>> selectPickupBranch(
    String branchId,
  ) => _select('branch:$branchId', FulfillmentMode.pickup, null);

  Future<Either<Failure, DeliverySelectionEntity>> _select(
    String call,
    FulfillmentMode mode,
    String? addressId,
  ) async {
    calls.add(call);
    final gate = selectGate;
    if (gate != null) {
      selectGate = null;
      await gate.future;
    }
    final failure = selectFailure;
    selectFailure = null;
    if (failure != null) return Left(failure);
    return Right(
      DeliverySelectionEntity(
        mode: mode,
        addressId: addressId,
        branchId: 'b1',
        branchName: 'Salmiya',
        zoneName: call,
        deliveryFeeFils: 500,
        etaMinutes: 45,
      ),
    );
  }

  @override
  Future<Either<Failure, OrderEntity>> placeOrder(CheckoutDraft draft) async {
    calls.add('place:${draft.paymentMethod.wireValue}');
    final gate = placeGate;
    if (gate != null) {
      placeGate = null;
      await gate.future;
    }
    final failure = placeFailure;
    placeFailure = null;
    if (failure != null) return Left(failure);
    return Right(OrderModel.fromJson(orderJson()).toEntity());
  }
}
