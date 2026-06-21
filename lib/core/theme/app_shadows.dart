import 'package:flutter/material.dart';

/// KeeTa `system.shadow` elevation tokens (yOffset / blur / opacity, light & dark
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
}
