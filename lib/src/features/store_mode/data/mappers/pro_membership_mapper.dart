import '../../domain/entities/pro_membership.dart';
import '../models/pro_program_model.dart';
import '../models/pro_subscription_model.dart';

/// [ProProgramModel] (wire) → [ProProgram]; plans in backend order.
extension ProProgramMapper on ProProgramModel {
  ProProgram toEntity() {
    final sorted = plans.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ProProgram(
      enabled: enabled,
      perks: ProPerks(
        freeDelivery: freeDelivery,
        pointsMultiplier: pointsMultiplier,
        discountPercent: discountPercent,
      ),
      plans: [
        for (final plan in sorted)
          ProPlan(
            id: plan.id,
            name: plan.name,
            slug: plan.slug,
            interval: ProMembershipWire.interval(plan.interval),
            intervalCount: plan.intervalCount,
            priceFils: plan.price,
            sortOrder: plan.sortOrder,
          ),
      ],
    );
  }
}

/// [ProSubscriptionModel] (wire) → [ProSubscription].
extension ProSubscriptionMapper on ProSubscriptionModel {
  ProSubscription toEntity() => ProSubscription(
    id: id,
    planId: planId,
    planName: planName,
    interval: ProMembershipWire.interval(interval),
    intervalCount: intervalCount,
    priceFils: price,
    status: switch (status) {
      'active' => ProSubscriptionStatus.active,
      'expired' => ProSubscriptionStatus.expired,
      'cancelled' => ProSubscriptionStatus.cancelled,
      _ => ProSubscriptionStatus.other,
    },
    currentPeriodEnd: currentPeriodEnd,
    cancelAtPeriodEnd: cancelAtPeriodEnd,
  );
}

abstract final class ProMembershipWire {
  static ProBillingInterval interval(String wire) => switch (wire) {
    'month' => ProBillingInterval.month,
    'year' => ProBillingInterval.year,
    _ => ProBillingInterval.other,
  };
}
