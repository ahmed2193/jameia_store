import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/jameia_image.dart';

/// One photo of the viewer's thumbnail strip: the photo contained on a
/// rounded light-grey tile, outlined in the brand colour while it is the
/// one shown ([selected]). A tap reports [onTap].
class PdpThumbnail extends StatelessWidget {
  const PdpThumbnail({
    super.key,
    required this.url,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String url;

  /// Accessibility label ("Image 2/5").
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double size = AppSize.s72;
  static const double ring = AppSize.s2;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          width: size,
          height: size,
          padding: const EdgeInsets.all(AppSpacing.s6),
          decoration: BoxDecoration(
            color: AppColors.smallBackground,
            borderRadius: BorderRadius.circular(AppSize.r12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.scrimTransparent,
              width: ring,
            ),
          ),
          child: JameiaImage(url: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
