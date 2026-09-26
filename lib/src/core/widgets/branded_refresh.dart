import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// Pull-to-refresh with Jameia branding. v1 wraps the platform [RefreshIndicator]
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
    this.edgeOffset = 0,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// How far down the spinner starts: the height of a bar pinned over the
  /// top of the list, so the spinner comes out from under it.
  final double edgeOffset;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.brandForeground,
      backgroundColor: AppColors.primary,
      displacement: 36,
      edgeOffset: edgeOffset,
      child: child,
    );
  }
}
