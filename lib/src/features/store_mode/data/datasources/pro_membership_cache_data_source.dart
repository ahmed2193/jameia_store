import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/pro_program_model.dart';
import '../models/pro_subscription_model.dart';
import '../models/pro_subscription_results.dart';

/// The Pro page as last shown: the programme (public — perks and plans, per
/// language) and the signed-in customer's subscription (customer-only —
/// nothing is kept for a guest — and wiped on sign-out). Parsed back with
/// the DTOs' own parsers.
abstract class ProMembershipCacheDataSource {
  /// `GET /v1/subscription-plans`.
  CacheSlot<ProProgramModel>? program();

  /// `GET /v1/account/subscription` — also what a subscribe / cancel reply
  /// replaces.
  CacheSlot<ProSubscriptionModel?>? subscription();
}

class ProMembershipCacheDataSourceImpl implements ProMembershipCacheDataSource {
  const ProMembershipCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const CacheNamespace programNamespace = CacheNamespace(
    'pro.program',
    scope: CacheScope.public,
    freshFor: Duration(minutes: 5),
    maxAge: Duration(days: 7),
  );

  static const CacheNamespace subscriptionNamespace = CacheNamespace(
    'pro.subscription',
    scope: CacheScope.customer,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 7),
  );

  @override
  CacheSlot<ProProgramModel>? program() => _slots.of(
    programNamespace,
    parse: (raw) => ProProgramModel.fromJson(
      ApiPayload.asMap(raw, EndPoints.subscriptionPlans),
    ),
  );

  @override
  CacheSlot<ProSubscriptionModel?>? subscription() =>
      _slots.of(subscriptionNamespace, parse: ProSubscriptionResults.parse);
}
