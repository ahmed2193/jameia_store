import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/loyalty_program.dart';
import '../../../../core/domain/entities/order_status.dart';

/// The store settings checkout obeys (`GET /v1/init` → `store.*`): its name
/// (the title bar's subtitle), whether cash on delivery is on and which
/// method it prefers, the loyalty programme, the Pro free-delivery perk and
/// maintenance. Store fields only: the customer's own data (wallet, points,
/// Pro membership) comes from the session.
class CheckoutStoreRules extends Equatable {
  const CheckoutStoreRules({
    this.storeName = '',
    this.codEnabled = true,
    this.defaultPaymentMethod = OrderPaymentMethod.cod,
    this.loyalty = LoyaltyProgram.none,
    this.proFreeDelivery = false,
    this.maintenance = false,
    this.maintenanceMessage = '',
  });

  /// Nothing read (not loaded, or the read failed): cash on delivery stays
  /// available and nothing is promised.
  static const CheckoutStoreRules unknown = CheckoutStoreRules();

  /// Already localized by the server (`Accept-Language`).
  final String storeName;
  final bool codEnabled;
  final OrderPaymentMethod defaultPaymentMethod;
  final LoyaltyProgram loyalty;

  /// Pro runs and its perks include free delivery.
  final bool proFreeDelivery;

  /// The store takes no orders (cart and order writes are refused).
  final bool maintenance;

  /// The server's own maintenance text; may be empty.
  final String maintenanceMessage;

  @override
  List<Object?> get props => [
    storeName,
    codEnabled,
    defaultPaymentMethod,
    loyalty,
    proFreeDelivery,
    maintenance,
    maintenanceMessage,
  ];
}
