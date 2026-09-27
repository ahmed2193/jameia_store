import 'package:flutter/material.dart';

/// Hero `system.shadow` elevation tokens (yOffset / blur / opacity, light & dark
/// identical). Colors taken from `system.shadowAlter` (#00000019 ≈ 10%).
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> low = [
    BoxShadow(color: Color(0x19000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x19000000), offset: Offset(0, 3), blurRadius: 6),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(color: Color(0x19000000), offset: Offset(0, 4), blurRadius: 18),
  ];

  /// Hairline shadow under a title bar (the search entry bar).
  static const List<BoxShadow> barBottom = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// Hairline shadow above a pinned bottom action bar.
  static const List<BoxShadow> barTop = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, -1), blurRadius: 3),
  ];

  /// The white loader disc floating over a page or the busy scrim: a soft,
  /// deep drop, so the disc lifts off white and dim alike.
  static const List<BoxShadow> loaderDisc = [
    BoxShadow(color: Color(0x24000000), offset: Offset(0, 6), blurRadius: 24),
  ];
}
