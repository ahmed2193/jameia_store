import 'package:flutter/widgets.dart';

import '../../../../../core/design/hero_icons.dart';

/// What the live map's camera button does.
enum LiveMapCameraAction {
  /// The camera follows the rider again (rides along where it can).
  follow,

  /// The camera shows the road ahead, from above.
  overview;

  /// i18n key of the button's words; widgets call `.tr()` on it.
  String get labelKey => switch (this) {
    follow => 'orders.live_recenter',
    overview => 'orders.live_overview',
  };

  IconData get icon => switch (this) {
    follow => HeroIcons.myLocation,
    overview => HeroIcons.pin,
  };
}
