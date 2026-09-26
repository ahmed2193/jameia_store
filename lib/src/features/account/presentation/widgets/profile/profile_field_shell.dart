import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The filled surface every profile input sits in (text fields, the date of
/// birth, the household stepper): a soft grey fill at rest, white with a
/// brand border while [focused], tinted red with a red border on [error].
/// The border is always 2dp — only its colour and the fill change (over
/// [AppMotion.fast]), so nothing is laid out again. Grows with large text:
/// [minHeight] is a floor, not a fixed height.
class ProfileFieldShell extends StatelessWidget {
  const ProfileFieldShell({
    super.key,
    required this.child,
    this.focused = false,
    this.error = false,
    this.padding = EdgeInsetsDirectional.zero,
  });

  static const double minHeight = AppSize.s52;
  static const double _borderWidth = AppSize.s2;

  /// The least height of what sits inside the border; a tappable row sizes
  /// itself to it so the whole field takes the tap.
  static const double contentMinHeight = minHeight - 2 * _borderWidth;
  static const BorderRadius radius = BorderRadius.all(
    Radius.circular(AppRadius.r3),
  );

  final Widget child;
  final bool focused;
  final bool error;
  final EdgeInsetsGeometry padding;

  Color get _fill {
    if (error) return AppColors.errorBg;
    return focused ? AppColors.white : AppColors.smallBackground;
  }

  Color get _border {
    if (error) return AppColors.error;
    return focused ? AppColors.primary : AppColors.smallBackground;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      constraints: const BoxConstraints(minHeight: minHeight),
      padding: padding,
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: radius,
        border: Border.all(color: _border, width: _borderWidth),
      ),
      child: child,
    );
  }
}
