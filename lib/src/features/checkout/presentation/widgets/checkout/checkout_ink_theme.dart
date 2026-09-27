import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';

/// The checkout's touch feedback: a flat brand-mint highlight
/// ([AppColors.pressTint]) instead of the grey Material sparkle, and no
/// splash. Wraps the checkout scroll view, the vouchers body and every
/// checkout sheet (through `CheckoutSheetFrame.show`), so every row and
/// button in them answers a finger the same way.
///
/// The highlight fade is the framework's own (no shader warm-up). The theme
/// is compared by value, so a rebuild with the same parent theme notifies
/// nothing below.
class CheckoutInkTheme extends StatelessWidget {
  const CheckoutInkTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: AppColors.pressTint,
      splashColor: AppColors.scrimTransparent,
    ),
    child: child,
  );
}
