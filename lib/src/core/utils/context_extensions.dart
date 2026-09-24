import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// Ergonomic `context.*` accessors for the Jameia design tokens and common
/// MediaQuery values. Feature code reads `context.colors.primaryText`, etc.,
/// so semantic tokens flip automatically between light/dark.
extension JameiaContextX on BuildContext {
  /// Brightness-resolved Jameia semantic color bundle.
  JameiaColors get colors =>
      Theme.of(this).extension<JameiaColors>() ?? JameiaColors.light;

  TextTheme get text => Theme.of(this).textTheme;

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get viewPadding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
