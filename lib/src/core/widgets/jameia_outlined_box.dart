import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';

/// The app's bordered input box (phone input, country code, OTP code, profile
/// fields): one place for the 45dp height, 6dp radius and hairline divider
/// border. Shared by auth and account, hence `core/widgets`.
class JameiaOutlinedBox extends StatelessWidget {
  const JameiaOutlinedBox({
    super.key,
    required this.child,
    this.height = AppSize.s45,
    this.padding,
    this.error = false,
  });

  final Widget child;
  final double height;
  final EdgeInsetsGeometry? padding;

  /// Paints the border in the error colour (invalid field).
  final bool error;

  static BoxDecoration decoration({bool error = false}) => BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.r6),
    border: Border.all(color: error ? AppColors.error : AppColors.divider),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: decoration(error: error),
      child: child,
    );
  }
}
