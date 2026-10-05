import 'package:easy_localization/easy_localization.dart';

import '../domain/entities/address_label.dart';
import '../domain/entities/hero_address_entity.dart';
import 'formatters.dart';

/// Localized text for a saved address, shared by every screen that shows one
/// (address list rows, the home delivery pill).
extension AddressDisplay on HeroAddressEntity {
  /// The tag as the customer reads it: "Home", "Work", … — or the custom
  /// label another client saved.
  String get tagText =>
      customLabel ??
      switch (labelKind) {
        AddressLabel.home => 'addr.tag.home'.tr(),
        AddressLabel.work => 'addr.tag.work'.tr(),
        AddressLabel.gathering => 'addr.tag.gathering'.tr(),
        AddressLabel.other => 'addr.tag.other'.tr(),
      };

  /// One short line for tight spots (the home pill): "Home · Salmiya".
  String get shortPlace => city.isEmpty ? tagText : '$tagText · $city';
}

/// The numbered parts of an address line.
enum AddressLinePart { block, street, building, floor, apartment }

/// One part of an address line, the same on every screen (the list row,
/// the form's header, the pin's label): a bare number reads with its name
/// ("Block 7", "Street 12"), a named part as it is ("Fahad Al-Salem
/// Street", "5 St. 6 Lane"). In a right-to-left line ([rtl]) the part keeps
/// its own direction: an English "5 St. 6 Lane" would read "St. 6 Lane 5"
/// in an Arabic one.
String addressLinePart(
  AddressLinePart part,
  String value, {
  required bool rtl,
}) {
  final kept = addressLineName(value, rtl: rtl);
  if (!_bareNumber.hasMatch(value)) return kept;
  final key = switch (part) {
    AddressLinePart.block => 'addr.line.block',
    AddressLinePart.street => 'addr.line.street',
    AddressLinePart.building => 'addr.line.building',
    AddressLinePart.floor => 'addr.line.floor',
    AddressLinePart.apartment => 'addr.line.apartment',
  };
  return key.tr(namedArgs: {'value': kept});
}

/// A name in an address line (the area), its own direction kept in a
/// right-to-left line ([rtl]).
String addressLineName(String value, {required bool rtl}) =>
    rtl ? Formatters.isolate(value) : value;

/// "7", "12A", Arabic-Indic digits: a number, maybe with a letter.
final RegExp _bareNumber = RegExp(
  r'^[0-9\u0660-\u0669\u06F0-\u06F9]+[A-Za-z\u0621-\u064A]?$',
);
