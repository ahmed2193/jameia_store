import 'package:equatable/equatable.dart';

/// How often a Pro plan renews.
enum ProBillingInterval { month, year, other }

enum ProSubscriptionStatus { active, expired, cancelled, other }

/// One Pro plan the customer can subscribe to (`GET /v1/subscription-plans`).
/// [name] arrives already resolved for the request language; money is fils.
class ProPlan extends Equatable {
  const ProPlan({
    required this.id,
    required this.name,
    this.slug = '',
    this.interval = ProBillingInterval.month,
    this.intervalCount = 1,
    this.priceFils = 0,
    this.sortOrder = 0,
  });

  static const int filsPerDinar = 1000;

  final String id;
  final String name;
  final String slug;
  final ProBillingInterval interval;

  /// Every [intervalCount] [interval]s (`1 month`, `1 year`).
  final int intervalCount;
  final int priceFils;
  final int sortOrder;

  double get priceKd => priceFils / filsPerDinar;

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    interval,
    intervalCount,
    priceFils,
    sortOrder,
  ];
}

/// What a Pro member gets (`perks` of the plans reply).
class ProPerks extends Equatable {
  const ProPerks({
    this.freeDelivery = false,
    this.pointsMultiplier = 1,
    this.discountPercent = 0,
  });

  final bool freeDelivery;
  final int pointsMultiplier;
  final int discountPercent;

  bool get hasPointsBoost => pointsMultiplier > 1;
  bool get hasDiscount => discountPercent > 0;

  @override
  List<Object?> get props => [freeDelivery, pointsMultiplier, discountPercent];
}

/// The Pro programme: whether the store runs it, its perks and its plans in
/// display order. This is what replaced the old offline "VIP ⇄ Mart" store
/// mode: member prices now come from a subscription, not from a local toggle.
class ProProgram extends Equatable {
  const ProProgram({
    this.enabled = false,
    this.perks = const ProPerks(),
    this.plans = const <ProPlan>[],
  });

  static const ProProgram empty = ProProgram();

  final bool enabled;
  final ProPerks perks;
  final List<ProPlan> plans;

  /// Nothing to sell: the programme is off or has no plan.
  bool get isUnavailable => !enabled || plans.isEmpty;

  @override
  List<Object?> get props => [enabled, perks, plans];
}

/// The customer's Pro subscription (`GET /v1/account/subscription`).
class ProSubscription extends Equatable {
  const ProSubscription({
    required this.id,
    required this.planId,
    this.planName = '',
    this.interval = ProBillingInterval.month,
    this.intervalCount = 1,
    this.priceFils = 0,
    this.status = ProSubscriptionStatus.other,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
  });

  final String id;
  final String planId;
  final String planName;
  final ProBillingInterval interval;
  final int intervalCount;
  final int priceFils;
  final ProSubscriptionStatus status;

  /// When the paid period ends (renews, or stops after a cancellation).
  final DateTime? currentPeriodEnd;

  /// Cancelled, but the paid period is still running.
  final bool cancelAtPeriodEnd;

  bool get isActive => status == ProSubscriptionStatus.active;

  /// Active and not already cancelled: the only state "cancel" applies to.
  bool get canCancel => isActive && !cancelAtPeriodEnd;

  double get priceKd => priceFils / ProPlan.filsPerDinar;

  @override
  List<Object?> get props => [
    id,
    planId,
    planName,
    interval,
    intervalCount,
    priceFils,
    status,
    currentPeriodEnd,
    cancelAtPeriodEnd,
  ];
}
