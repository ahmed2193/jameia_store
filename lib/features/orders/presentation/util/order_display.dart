import 'package:easy_localization/easy_localization.dart';

import '../../../../core/data/models/models.dart' show localizedCatalogName;
import '../../domain/entities/order.dart';

/// Presentation-side, active-locale display for the order entities.
///
/// The entities are framework-free (raw bilingual fields + a payment-method
/// selector only); resolving the visible strings is a presentation concern, so
/// it lives here. Reuses the catalogue's canonical locale picker
/// (`localizedCatalogName`, which reads the live `Intl.defaultLocale`) so a
/// language switch flips the text on the next rebuild — matching the old
/// `KeetaOrder`/`OrderItem` display getters exactly.
extension OrderDisplay on OrderEntity {
  String get displayShopName => localizedCatalogName(shopName, shopNameAr);
  String get displayDate => localizedCatalogName(date, dateAr);

  /// Payment-method label. Brand names + masked card stay verbatim; the generic
  /// "Cash on delivery" is localized (case 2). Mirrors the old
  /// `KeetaOrder.paymentMethod` getter.
  String get paymentMethod {
    switch (paymentMethodCase) {
      case 0:
        return 'Apple Pay';
      case 1:
        return 'Google Pay';
      case 2:
        return 'checkout.pay_cod'.tr();
      default:
        return 'Visa •• 42';
    }
  }
}

extension OrderItemDisplay on OrderItemEntity {
  String get displayName => localizedCatalogName(name, nameAr);
}
