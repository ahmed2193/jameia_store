import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/cart_offer_progress_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/offer_reward_entity.dart';

/// One cart offer as the deals strip and the "Buy more, save more" sheet
/// show it: already earned ([applied], with what it [savedFils]) or still to
/// unlock (how much is missing, how far along the cart is).
///
/// The live server moves an offer from `offerProgress[]` to
/// `appliedOffers[]` once the cart reaches it; an applied free delivery
/// reports `discount: 0` (the fee simply drops to zero).
class CartDealEntity extends Equatable {
  const CartDealEntity({
    required this.offerId,
    required this.name,
    this.reward = const OfferRewardEntity(),
    this.applied = false,
    this.savedFils = 0,
    this.kind = OfferProgressKind.other,
    this.remainingValue = 0,
    this.fraction = 0,
    this.contextId,
    this.contextName,
  });

  final String offerId;

  /// Resolved for the request language by the server.
  final String name;
  final OfferRewardEntity reward;
  final bool applied;
  final int savedFils;
  final OfferProgressKind kind;

  /// Fils for [OfferProgressKind.subtotal], pieces otherwise.
  final int remainingValue;

  /// 0..1 towards the offer; `1` once [applied].
  final double fraction;

  /// The category (or product) the offer counts, when it counts one.
  final String? contextId;
  final String? contextName;

  bool get isSubtotal => kind == OfferProgressKind.subtotal;

  /// Still to unlock by adding pieces of one category: the sheet lists that
  /// category's products for it.
  String? get categoryId =>
      !applied && kind == OfferProgressKind.category ? contextId : null;

  double get savedKd => savedFils / CatalogProductEntity.filsPerDinar;
  double get remainingKd => remainingValue / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    offerId,
    name,
    reward,
    applied,
    savedFils,
    kind,
    remainingValue,
    fraction,
    contextId,
    contextName,
  ];
}

/// Every offer of the cart, earned ones first, then the ones still to
/// unlock — both in the server's order (it lists the closest one first).
class CartOffersView extends Equatable {
  const CartOffersView({this.deals = const <CartDealEntity>[]});

  factory CartOffersView.of(CartEntity cart) => CartOffersView(
    deals: <CartDealEntity>[
      for (final offer in cart.appliedOffers)
        CartDealEntity(
          offerId: offer.offerId,
          name: offer.name,
          reward: offer.reward,
          applied: true,
          savedFils: offer.discountFils,
          fraction: 1,
        ),
      for (final progress in cart.offerProgress)
        if (!progress.isReached)
          CartDealEntity(
            offerId: progress.offerId,
            name: progress.name,
            reward: progress.reward,
            kind: progress.kind,
            remainingValue: progress.remainingValue,
            fraction: progress.fraction,
            contextId: progress.contextId,
            contextName: progress.contextName,
          ),
    ],
  );

  static const CartOffersView empty = CartOffersView();

  final List<CartDealEntity> deals;

  bool get isEmpty => deals.isEmpty;
  bool get hasEarned => deals.any((deal) => deal.applied);

  /// The deal the strip over the checkout bar talks about: the closest one
  /// still to unlock; `null` once every offer is earned.
  CartDealEntity? get next {
    for (final deal in deals) {
      if (!deal.applied) return deal;
    }
    return null;
  }

  /// Every offer of the store is in the cart: "you've got the best deal".
  bool get allEarned => deals.isNotEmpty && next == null;

  /// The deal the sheet opens on: the next one to unlock, else the first.
  CartDealEntity? get initial => next ?? (deals.isEmpty ? null : deals.first);

  CartDealEntity? byId(String? offerId) {
    for (final deal in deals) {
      if (deal.offerId == offerId) return deal;
    }
    return null;
  }

  @override
  List<Object?> get props => [deals];
}
