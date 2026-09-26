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
  static const int monthsPerYear = 12;

  final String id;
  final String name;
  final String slug;
  final ProBillingInterval interval;

  /// Every [intervalCount] [interval]s (`1 month`, `1 year`).
  final int intervalCount;
  final int priceFils;
  final int sortOrder;

  double get priceKd => priceFils / filsPerDinar;

  /// How many months one billing period covers; `null` for an interval the
  /// app does not know (it cannot be compared per month).
  int? get months {
    if (intervalCount < 1) return null;
    return switch (interval) {
      ProBillingInterval.month => intervalCount,
      ProBillingInterval.year => intervalCount * monthsPerYear,
      ProBillingInterval.other => null,
    };
  }

  /// The price spread over one month, rounded to the fils (the website's
  /// "2.083 KWD / month" for the annual plan); `null` when [months] is.
  int? get monthlyPriceFils {
    final count = months;
    return count == null ? null : (priceFils / count).round();
  }

  double? get monthlyPriceKd {
    final fils = monthlyPriceFils;
    return fils == null ? null : fils / filsPerDinar;
  }

  /// Billed for more than one month at a time (the per-month price differs
  /// from the charged one).
  bool get isMultiMonth => (months ?? 1) > 1;

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

  ProPlan? planById(String? id) {
    if (id == null) return null;
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  /// The plan with the lowest price per month, when at least two plans can
  /// be compared and one is actually cheaper; `null` otherwise. The website
  /// highlights the same plan.
  ProPlan? get bestValuePlan {
    ProPlan? best;
    var comparable = 0;
    var highest = 0;
    for (final plan in plans) {
      final perMonth = plan.monthlyPriceFils;
      if (perMonth == null) continue;
      comparable++;
      if (perMonth > highest) highest = perMonth;
      if (best == null || perMonth < best.monthlyPriceFils!) best = plan;
    }
    if (comparable < 2 || best == null) return null;
    return best.monthlyPriceFils! < highest ? best : null;
  }

  /// "Save N%" of [plan] against the dearest plan per month, rounded like the
  /// website (`round((max − perMonth) / max × 100)`); 0 when there is nothing
  /// to save or [plan] cannot be compared.
  int savingPercentOf(ProPlan plan) {
    final perMonth = plan.monthlyPriceFils;
    if (perMonth == null) return 0;
    var highest = 0;
    for (final other in plans) {
      final value = other.monthlyPriceFils;
      if (value != null && value > highest) highest = value;
    }
    if (highest <= 0 || perMonth >= highest) return 0;
    return ((highest - perMonth) / highest * 100).round();
  }

  /// The "Save N%" chip of every plan, in [plans] order: only the
  /// [bestValuePlan] wears one (its [savingPercentOf]); every other plan, and
  /// every plan when none is the best value, gets 0 (no chip).
  List<int> get badgeSavings {
    final best = bestValuePlan;
    return [for (final plan in plans) plan == best ? savingPercentOf(plan) : 0];
  }

  /// The plan the page opens on: the customer's current plan, else the best
  /// value, else the first one; `null` when there is no plan.
  ProPlan? initialPlan({String? currentPlanId}) =>
      planById(currentPlanId) ??
      bestValuePlan ??
      (plans.isEmpty ? null : plans.first);

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

  /// The customer still gets the Pro perks: active, or cancelled while the
  /// paid period is still running. The docs return a cancelled-but-running
  /// subscription as `cancelled` + `cancelAtPeriodEnd`, and the website reads
  /// `cancelAtPeriodEnd` first the same way; `expired` never has benefits.
  bool get hasBenefits =>
      status != ProSubscriptionStatus.expired &&
      (isActive || cancelAtPeriodEnd);

  /// Active and not already cancelled: the only state "cancel" applies to.
  bool get canCancel => isActive && !cancelAtPeriodEnd;

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
