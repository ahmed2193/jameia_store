import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';

/// Fills of a [JameiaSurfaceCard].
enum JameiaSurfaceTone {
  /// White with a hairline border.
  white(AppColors.white),

  /// Muted grey.
  muted(AppColors.smallBackground),

  /// Brand-green wash (offers, progress, good news).
  brand(AppColors.brandLightBg);

  const JameiaSurfaceTone(this.fill);

  final Color fill;
}

/// Flat rounded card: radius 16, no shadow — a hairline border on white, a
/// flat tint otherwise. Tappable when [onTap] is set (ripple, no scale). A
/// [Material], so rows inside keep their ink.
class JameiaSurfaceCard extends StatelessWidget {
  const JameiaSurfaceCard({
    super.key,
    required this.child,
    this.tone = JameiaSurfaceTone.white,
    this.padding = const EdgeInsets.all(AppSpacing.s16),
    this.radius = AppRadius.media,
    this.onTap,
  });

  final Widget child;
  final JameiaSurfaceTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Material(
      color: tone.fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: tone == JameiaSurfaceTone.white
            ? const BorderSide(color: AppColors.divider)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
