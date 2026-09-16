import '../../../../core/data/models/models.dart';
import '../../domain/entities/keeta_order_entity.dart';

/// DTO → entity mapping for a placed order. The persisted core [KeetaOrder]
/// (with its items / rider + `easy_localization`-backed display getters) stays
/// in the shared catalogue; only the framework-free scalar summary flows back
/// to the checkout presentation as a [KeetaOrderEntity].
extension OrderMapper on KeetaOrder {
  KeetaOrderEntity toEntity() => KeetaOrderEntity(
        id: id,
        shopName: shopName,
        shopNameAr: shopNameAr,
        shopId: shopId,
        shopLogo: shopLogo,
        status: status,
        statusStep: statusStep,
        total: total,
        date: date,
        dateAr: dateAr,
      );
}
