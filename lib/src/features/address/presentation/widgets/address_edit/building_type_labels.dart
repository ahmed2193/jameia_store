import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../domain/entities/building_type.dart';

// The words and the glyph of each building type.

/// "House", "Apartment" …
String buildingTypeName(BuildingType type) => switch (type) {
  BuildingType.house => 'addr.struct.house'.tr(),
  BuildingType.apartment => 'addr.struct.apartment'.tr(),
  BuildingType.office => 'addr.struct.office'.tr(),
  BuildingType.other => 'addr.struct.other'.tr(),
};

IconData buildingTypeIcon(BuildingType type) => switch (type) {
  BuildingType.house => HeroIcons.home,
  BuildingType.apartment => HeroIcons.apartment,
  BuildingType.office => HeroIcons.office,
  BuildingType.other => HeroIcons.pin,
};
