import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_image.dart';
import 'pdp_outlined_tile.dart';

/// One photo of the viewer's thumbnail strip, Hero style: the photo
/// contained on a white rounded tile with a hairline edge, ringed in the
/// brand colour while it is the one shown ([selected]) — the ring eases in
/// without moving the photo ([PdpOutlinedTile]). A tap reports [onTap].
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

  static const double size = AppSize.s64;

  /// Edge plus padding: where the photo sits in the tile.
  static const double _inset = AppSpacing.s6;

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
        child: PdpOutlinedTile(
          selected: selected,
          selectedColor: AppColors.primary,
          radius: AppSize.r12,
          inset: _inset,
          width: size,
          height: size,
          child: HeroImage(url: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
