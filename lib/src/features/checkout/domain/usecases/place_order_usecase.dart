import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/checkout_block_reason.dart';
import '../entities/checkout_cart_facts.dart';
import '../entities/checkout_draft.dart';
import '../entities/checkout_store_rules.dart';
import '../repositories/checkout_repository.dart';

/// `POST /v1/orders` once nothing blocks the order: every content rule of
/// the checkout ([CheckoutBlockReason.resolve] — destination, window,
/// notes, the cart's own blocks, maintenance, payment) is checked here, on
/// the full facts, before any request goes out. A blocked order is a
/// [ValidationFailure] named after its reason.
class PlaceOrderUseCase implements UseCase<OrderEntity, PlaceOrderParams> {
  const PlaceOrderUseCase(this._repository);
  final CheckoutRepository _repository;

  @override
  Future<Either<Failure, OrderEntity>> call(PlaceOrderParams params) {
    final reason = params.blockReason;
    if (reason != null) {
      return Future.value(Left(ValidationFailure(reason.name)));
    }
    return _repository.placeOrder(params.draft);
  }
}

/// Everything the block rule reads: the draft, whether the server resolved
/// its destination, the store's rules and the cart's facts. Every field is
/// required, so a caller cannot skip the cart or wallet checks by leaving
/// them out.
class PlaceOrderParams extends Equatable {
  const PlaceOrderParams({
    required this.draft,
    required this.hasSelection,
    required this.rules,
    required this.cart,
  });

  final CheckoutDraft draft;
  final bool hasSelection;
  final CheckoutStoreRules rules;
  final CheckoutCartFacts cart;

  /// The first reason this order cannot go, or `null`.
  CheckoutBlockReason? get blockReason => CheckoutBlockReason.resolve(
    draft: draft,
    hasSelection: hasSelection,
    rules: rules,
    cart: cart,
  );

  @override
  List<Object?> get props => [draft, hasSelection, rules, cart];
}
