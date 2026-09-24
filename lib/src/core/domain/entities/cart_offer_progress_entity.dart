import 'package:equatable/equatable.dart';

import 'catalog_product_entity.dart';
import 'offer_reward_entity.dart';

/// What the offer counts: cart subtotal (fils), pieces of one product, or
/// pieces of one category.
enum OfferProgressKind { subtotal, item, category, other }

/// "Add X more to unlock Y" (`GET /v1/cart` → `offerProgress[]`).
class CartOfferProgressEntity extends Equatable {
  const CartOfferProgressEntity({
    required this.offerId,
    required this.name,
    this.kind = OfferProgressKind.other,
    this.currentValue = 0,
    this.targetValue = 0,
    this.remainingValue = 0,
    this.contextId,
    this.contextName,
    this.reward = const OfferRewardEntity(),
    this.rewardProduct,
  });

  final String offerId;
  final String name;
  final OfferProgressKind kind;

  /// Fils for [OfferProgressKind.subtotal], pieces otherwise.
  final int currentValue;
  final int targetValue;
  final int remainingValue;

  /// The product / category the offer counts, when it counts one.
  final String? contextId;
  final String? contextName;
  final OfferRewardEntity reward;
  final CatalogProductEntity? rewardProduct;

  bool get isSubtotal => kind == OfferProgressKind.subtotal;
  bool get isReached => remainingValue <= 0;

  /// 0..1 progress towards [targetValue].
  double get fraction => targetValue <= 0
      ? (isReached ? 1 : 0)
      : (currentValue / targetValue).clamp(0, 1).toDouble();

  double get remainingKd => remainingValue / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    offerId,
    name,
    kind,
    currentValue,
    targetValue,
    remainingValue,
    contextId,
    contextName,
    reward,
    rewardProduct,
  ];
}
