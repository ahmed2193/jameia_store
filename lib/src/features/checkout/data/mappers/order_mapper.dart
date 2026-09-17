import '../../../../core/data/models/models.dart';
import '../../domain/entities/jameia_order_entity.dart';

/// DTO → entity mapping for a placed order. The persisted core [JameiaOrder]
/// (with its items / rider + `easy_localization`-backed display getters) stays
/// in the shared catalogue; only the framework-free scalar summary flows back
/// to the checkout presentation as a [JameiaOrderEntity].
extension OrderMapper on JameiaOrder {
  JameiaOrderEntity toEntity() => JameiaOrderEntity(
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
