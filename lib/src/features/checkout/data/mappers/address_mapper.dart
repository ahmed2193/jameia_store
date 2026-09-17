import '../../../../core/data/models/models.dart';
import '../../domain/entities/jameia_address_entity.dart';

/// DTO → entity mapping for the delivery address. Carries the raw brief/line/
/// area parts so the entity can recompose [JameiaAddressEntity.fullText] itself
/// (a pure string join, no locale) — keeping the core [JameiaAddress] DTO out of
/// the domain.
extension AddressMapper on JameiaAddress {
  JameiaAddressEntity toEntity() => JameiaAddressEntity(
    id: id,
    label: label,
    brief: brief,
    line: line,
    area: area,
    recipient: recipient,
    phone: phone,
  );
}
