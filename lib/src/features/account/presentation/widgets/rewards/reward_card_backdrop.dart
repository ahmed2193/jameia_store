import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// Background of a reward card's art: the warm amber → orange gradient, a
/// soft highlight at the top-end corner and a large faded tier medal (the
/// Hero medal, [HeroIcons.medal], tinted white) overhanging
/// the bottom-end corner, gently floating when [floats]. Decorative only;
/// the parent clips it to the card's corners (a locked tier's veil and lock
/// sit over it).
class RewardCardBackdrop extends StatelessWidget {
  const RewardCardBackdrop({super.key, required this.floats});

  final bool floats;

  static const List<Color> _gradient = [
    AppColors.proAmber,
    AppColors.accent3,
    kHeroPillPin,
  ];
  static const double _giftOverhang = -AppSpacing.s12;
  static const double _giftOpacity = 0.24;
  static final Color _giftTint = AppColors.white.withValues(
    alpha: _giftOpacity,
  );
  static const double _floatAmplitude = AppSpacing.s4;
  static const double _highlightAlpha = 0.28;
  static final List<Color> _highlight = [
    AppColors.white.withValues(alpha: _highlightAlpha),
    AppColors.white.withValues(alpha: 0),
  ];
  static const double _highlightOverhang = -AppSpacing.s40;

  @override
  Widget build(BuildContext context) {
    final gift = HeroIcon(HeroIcons.medal, size: AppSize.s96, color: _giftTint);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: _gradient,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PositionedDirectional(
              top: _highlightOverhang,
              end: _highlightOverhang,
              child: SizedBox.square(
                dimension: AppSize.s140,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: _highlight),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: _giftOverhang,
              bottom: _giftOverhang,
              child: floats
                  ? FloatLoop(amplitude: _floatAmplitude, child: gift)
                  : gift,
            ),
          ],
        ),
      ),
    );
  }
}
