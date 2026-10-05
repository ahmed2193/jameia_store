import 'package:easy_localization/easy_localization.dart';

import '../../../domain/entities/address_draft.dart';
import '../../../domain/entities/address_field.dart';
import '../../../domain/entities/building_type.dart';

// Localized labels and error text for the address form fields.

/// The label over [field] in a [type] building's form (a house asks for its
/// "House number", an office for its "Office number"); an optional field
/// says so.
String addressFieldLabel(AddressField field, BuildingType type) {
  final label = switch (field) {
    AddressField.city => 'addr.field.area'.tr(),
    AddressField.block => 'addr.field.block'.tr(),
    AddressField.street => 'addr.field.street'.tr(),
    AddressField.building =>
      (type == BuildingType.house
              ? 'addr.field.house_number'
              : 'addr.field.building')
          .tr(),
    AddressField.floor => 'addr.field.floor'.tr(),
    AddressField.apartment => switch (type) {
      BuildingType.office => 'addr.field.office_number'.tr(),
      BuildingType.other => 'addr.field.unit'.tr(),
      BuildingType.house ||
      BuildingType.apartment => 'addr.field.apt_number'.tr(),
    },
    AddressField.phone => 'addr.field.phone_label'.tr(),
    AddressField.notes => 'addr.details.notes_title'.tr(),
  };
  return AddressDraft.isRequired(field)
      ? label
      : '$label (${'common.optional'.tr()})';
}

/// The inline message for [error] on [field]; `null` when the value is valid.
String? addressFieldErrorText(AddressField field, AddressFieldError? error) =>
    switch (error) {
      null => null,
      AddressFieldError.required => 'addr.field_required'.tr(),
      AddressFieldError.invalidPhone => 'addr.phone_format'.tr(),
      AddressFieldError.tooLong => 'addr.field_too_long'.tr(
        namedArgs: {'max': '${AddressDraft.maxLengthOf(field)}'},
      ),
    };
