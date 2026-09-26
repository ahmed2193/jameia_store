import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/responsive/app_size.dart';

/// Warm gradient disc with a gift — the invite banner's badge, in the
/// amber → orange of the Rewards hero.
class MineGiftBadge extends StatelessWidget {
  const MineGiftBadge({super.key});

  static const double _size = AppSize.s44;
  static const double _glyph = AppSize.s22;
  static const List<Color> _warm = [
    AppColors.proAmber,
    AppColors.accent3,
    kJameiaPillPin,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: _warm,
        ),
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        size: _glyph,
        color: AppColors.white,
      ),
    );
  }
}
