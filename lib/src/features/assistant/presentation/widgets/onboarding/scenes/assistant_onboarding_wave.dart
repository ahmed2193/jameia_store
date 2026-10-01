import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../core/design/hero_icons.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../../../../../core/widgets/hero_icon.dart';

/// The hello demo's centre: a white disc with the assistant's sparkle, and
/// a ring of brand colour that spreads from it once. The hello itself is
/// the mascot's own painted wave up top (no emoji: platform glyphs are not
/// brand art — docs/motion §9.6 §5 row 12).
class AssistantOnboardingWave extends StatelessWidget {
  const AssistantOnboardingWave({
    super.key,
    required this.pop,
    required this.ring,
  });

  /// The disc's scale (a spring: it passes `1` on its way in).
  final double pop;

  /// How far the ring has spread, `0 → 1`; gone at both ends.
  final double ring;

  static const double _disc = AppSize.s76;
  static const double _glyph = AppSize.s36;
  static const double _ringGrowth = 0.75;
  static const double _ringAlpha = 0.5;
  static const double _ringWidth = AppSize.s2;
  static const BoxDecoration _face = BoxDecoration(
    color: AppColors.white,
    shape: BoxShape.circle,
    boxShadow: AppShadows.medium,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _disc,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (ring > 0 && ring < 1)
            Positioned.fill(
              child: Transform.scale(
                scale: 1 + ring * _ringGrowth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: (1 - ring) * _ringAlpha,
                      ),
                      width: _ringWidth,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Transform.scale(
              scale: pop,
              child: const DecoratedBox(
                decoration: _face,
                child: HeroIcon(
                  HeroIcons.sparkle,
                  size: _glyph,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
