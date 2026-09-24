import 'package:easy_localization/easy_localization.dart';

import '../domain/entities/address_label.dart';
import '../domain/entities/jameia_address_entity.dart';

/// Localized text for a saved address, shared by every screen that shows one
/// (address list rows, the home delivery pill).
extension AddressDisplay on JameiaAddressEntity {
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
