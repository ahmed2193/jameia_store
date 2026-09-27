import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';

/// Pinned bottom action bar: white, a hairline shadow on top, 16 dp gutters,
/// above the home indicator. Put the screen's primary `AppButton` (height 52)
/// inside.
class HeroBottomBar extends StatelessWidget {
  const HeroBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.gutter,
      AppSpacing.s12,
      AppSpacing.gutter,
      AppSpacing.s12,
    ),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: AppShadows.barTop,
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
