import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pull-to-refresh with KeeTa branding. v1 wraps the platform [RefreshIndicator]
/// tinted brand-yellow (so the spinner matches the brand) over a stable API; a
/// future v2 can swap in a custom `lottieRefresh` header without touching call
/// sites. Reduced-motion is handled by [RefreshIndicator] itself (the OS scales
/// the spinner), so no extra gate is needed here.
///
/// The [child] must be a scrollable (or contain one with
/// `AlwaysScrollableScrollPhysics`) for the pull gesture to register.
class BrandedRefresh extends StatelessWidget {
  const BrandedRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.brandForeground,
      backgroundColor: AppColors.primary,
      displacement: 36,
      child: child,
    );
  }
}
