import 'package:flutter/material.dart';

import '../design/jameia_assets.dart';
import '../motion/motion_widgets.dart';
import '../../config/theme/app_spacing.dart';

/// Favorite / wishlist toggle with Jameia's heart pop. Tapping flips [liked] and
/// pops the heart glyph (filled-red when liked, empty when not). Uses
/// [PressScale] for the tap feel and [PopScale] for the swap pop.
class HeartPopButton extends StatelessWidget {
  const HeartPopButton({
    super.key,
    required this.liked,
    required this.onChanged,
    this.size = 24,
  });

  final bool liked;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () => onChanged(!liked),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: PopScale(
          popKey: liked,
          child: Image.asset(
            liked ? JameiaAssets.shopRedHeart : JameiaAssets.shopEmptyHeart,
            width: size,
            height: size,
          ),
        ),
      ),
    );
  }
}
