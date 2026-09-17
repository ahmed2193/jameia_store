import 'package:easy_localization/easy_localization.dart';

import '../../../../../core/utils/jameia_geocode.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bilingual EN · AR label helpers for the address FORM schema. Shared by the
// extracted address-edit form widgets (schema fields, chips, drop-spot picker).
// ─────────────────────────────────────────────────────────────────────────────

String fieldLabel(AddrField f) {
  switch (f) {
    case AddrField.area:
      return 'addr.field.area'.tr();
    case AddrField.buildingName:
      return 'addr.field.building_name'.tr();
    case AddrField.aptNumber:
      return 'addr.field.apt_number'.tr();
    case AddrField.unitOrFloor:
      return 'addr.field.unit_floor'.tr();
    case AddrField.companyName:
      return 'addr.field.company_name'.tr();
    case AddrField.street:
      return 'addr.field.street'.tr();
    case AddrField.block:
      return 'addr.field.block'.tr();
    case AddrField.avenue:
      // "Avenue (optional)" — avenue label + common.optional suffix.
      return '${'addr.field.avenue'.tr()} (${'common.optional'.tr()})';
    case AddrField.additionalDirection:
      return '${'addr.field.additional_direction'.tr()} '
          '(${'common.optional'.tr()})';
    case AddrField.recipient:
      return 'addr.field.recipient'.tr();
    case AddrField.phone:
      return 'addr.field.phone'.tr();
    case AddrField.note:
      return 'addr.field.note'.tr();
  }
}

String structLabel(StructType t) {
  switch (t) {
    case StructType.apartment:
      return 'addr.struct.apartment'.tr();
    case StructType.house:
      return 'addr.struct.house'.tr();
    case StructType.office:
      return 'addr.struct.office'.tr();
  }
}

String dropSpotLabel(String spot) {
  switch (spot) {
    case 'frontDoor':
      return 'dropoff.front_door'.tr();
    case 'lobby':
      return 'dropoff.lobby'.tr();
    case 'frontDesk':
      return 'dropoff.reception'.tr();
    default:
      return 'addr.tag.other'.tr();
  }
}

const List<String> dropSpots = ['frontDoor', 'lobby', 'frontDesk', 'other'];
