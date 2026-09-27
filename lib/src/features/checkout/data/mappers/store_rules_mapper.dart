import '../../../../core/data/mappers/loyalty_program_mapper.dart';
import '../../../../core/domain/entities/order_status.dart';
import '../../domain/entities/checkout_store_rules.dart';
import '../models/store_rules_model.dart';

/// [StoreRulesModel] (wire) → [CheckoutStoreRules]. The order route takes
/// `cod` | `wallet` only, so any other default method means cash on
/// delivery.
extension StoreRulesMapper on StoreRulesModel {
  CheckoutStoreRules toEntity() => CheckoutStoreRules(
    storeName: storeName,
    codEnabled: codEnabled,
    defaultPaymentMethod: defaultMethod == OrderPaymentMethod.wallet.wireValue
        ? OrderPaymentMethod.wallet
        : OrderPaymentMethod.cod,
    loyalty: loyalty.toEntity(),
    proFreeDelivery: proFreeDelivery,
    maintenance: maintenanceMode,
    maintenanceMessage: maintenanceMessage,
  );
}
