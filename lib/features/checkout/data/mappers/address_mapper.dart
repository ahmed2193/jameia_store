import '../../../../core/data/models/models.dart';
import '../../domain/entities/keeta_address_entity.dart';

/// DTO → entity mapping for the delivery address. Carries the raw brief/line/
/// area parts so the entity can recompose [KeetaAddressEntity.fullText] itself
/// (a pure string join, no locale) — keeping the core [KeetaAddress] DTO out of
/// the domain.
extension AddressMapper on KeetaAddress {
  KeetaAddressEntity toEntity() => KeetaAddressEntity(
        id: id,
        label: label,
        brief: brief,
        line: line,
        area: area,
        recipient: recipient,
        phone: phone,
      );
}
