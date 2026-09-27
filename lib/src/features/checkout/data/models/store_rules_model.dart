import '../../../../core/data/models/json_read.dart';
import '../../../../core/data/models/loyalty_program_model.dart';

/// `GET /v1/init` → the `store` fields checkout obeys:
/// `store.name`, `store.payment.{codEnabled, defaultMethod}`,
/// `store.loyalty` (parsed by the core [LoyaltyProgramModel]),
/// `store.pro.{enabled, perks.freeDelivery}`, `store.maintenanceMode` and
/// `store.maintenanceMessage`. Store fields only — `user.*` (wallet, points,
/// Pro membership) belongs to the session and is never kept here. A missing
/// block or field falls back to the default (cash on delivery on, nothing
/// promised).
class StoreRulesModel {
  const StoreRulesModel({
    this.storeName = '',
    this.codEnabled = true,
    this.defaultMethod = '',
    this.loyalty = const LoyaltyProgramModel(),
    this.proFreeDelivery = false,
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
  });

  static const String storeKey = 'store';
  static const String nameKey = 'name';
  static const String paymentKey = 'payment';
  static const String codEnabledKey = 'codEnabled';
  static const String defaultMethodKey = 'defaultMethod';
  static const String proKey = 'pro';
  static const String enabledKey = 'enabled';
  static const String perksKey = 'perks';
  static const String freeDeliveryKey = 'freeDelivery';
  static const String maintenanceModeKey = 'maintenanceMode';
  static const String maintenanceMessageKey = 'maintenanceMessage';

  /// Reads the whole init snapshot ([results] is the envelope's `results`).
  factory StoreRulesModel.fromInitJson(Map<String, dynamic> results) {
    final loyalty = LoyaltyProgramModel.fromInitJson(results);
    final store = JsonRead.object(results[storeKey]);
    if (store == null) return StoreRulesModel(loyalty: loyalty);
    final payment = JsonRead.object(store[paymentKey]);
    final pro = JsonRead.object(store[proKey]);
    final perks = JsonRead.object(pro?[perksKey]);
    return StoreRulesModel(
      storeName: JsonRead.string(store[nameKey]) ?? '',
      codEnabled: JsonRead.flag(payment?[codEnabledKey], fallback: true),
      defaultMethod: JsonRead.string(payment?[defaultMethodKey]) ?? '',
      loyalty: loyalty,
      // Claimed only when the server says both: Pro runs and it includes
      // free delivery.
      proFreeDelivery:
          JsonRead.flag(pro?[enabledKey]) &&
          JsonRead.flag(perks?[freeDeliveryKey]),
      maintenanceMode: JsonRead.flag(store[maintenanceModeKey]),
      maintenanceMessage: JsonRead.string(store[maintenanceMessageKey]) ?? '',
    );
  }

  /// Server-localized (`Accept-Language`).
  final String storeName;
  final bool codEnabled;

  /// `cod` | `knet` | `card` | `apple_pay` in the spec; empty when absent.
  final String defaultMethod;
  final LoyaltyProgramModel loyalty;
  final bool proFreeDelivery;
  final bool maintenanceMode;
  final String maintenanceMessage;
}
