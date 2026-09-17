import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';

/// Parse a `#RRGGBB` / `#AARRGGBB` hex string into a [Color]. Returns [fallback]
/// on malformed input. Shared by promo chips, kingkong tiles, tiles area, etc.
Color hexColor(String hex, [Color fallback = AppColors.primary]) {
  var s = hex.trim().replaceFirst('#', '');
  if (s.isEmpty) return fallback;
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(v);
}
