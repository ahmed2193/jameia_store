import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_field_shell.dart';

/// The surface every profile input sits in (text fields, the date of birth,
/// the household stepper): the app's one field look ([HeroFieldShell] —
/// white, a hairline at rest, an ink outline while [focused], red on
/// [error]). Only the outline's colour changes, so nothing is laid out
/// again. Grows with large text: [minHeight] is a floor, not a fixed height.
class ProfileFieldShell extends StatelessWidget {
  const ProfileFieldShell({
    super.key,
    required this.child,
    this.focused = false,
    this.error = false,
    this.padding = EdgeInsetsDirectional.zero,
  });

  static const double minHeight = AppSize.s52;

  /// The least height of what sits inside the border; a tappable row sizes
  /// itself to it so the whole field takes the tap.
  static const double contentMinHeight =
      minHeight - 2 * HeroFieldShell.hairline;
  static const BorderRadius radius = HeroFieldShell.radius;

  final Widget child;
  final bool focused;
  final bool error;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return HeroFieldShell(
      focused: focused,
      error: error,
      padding: padding,
      minHeight: minHeight,
      child: child,
    );
  }
}
