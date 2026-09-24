import 'package:easy_localization/easy_localization.dart';

import '../../../domain/entities/address_draft.dart';
import '../../../domain/entities/address_field.dart';

// Localized hint / error text for the address form fields.

/// The hint of [field]; an optional field says so.
String addressFieldHint(AddressField field) {
  final label = switch (field) {
    AddressField.city => 'addr.field.area'.tr(),
    AddressField.block => 'addr.field.block'.tr(),
    AddressField.street => 'addr.field.street'.tr(),
    AddressField.building => 'addr.field.building'.tr(),
    AddressField.floor => 'addr.field.floor'.tr(),
    AddressField.apartment => 'addr.field.apartment'.tr(),
    AddressField.phone => 'addr.field.phone'.tr(),
    AddressField.notes => 'addr.field.note'.tr(),
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
