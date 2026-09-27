import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../core/responsive/app_size.dart';

/// The hello demo's centre: a white disc where a hand waves, and a ring of
/// brand colour that spreads from it once.
class AssistantOnboardingWave extends StatelessWidget {
  const AssistantOnboardingWave({
    super.key,
    required this.pop,
    required this.wave,
    required this.ring,
  });

  /// The disc's scale (a spring: it passes `1` on its way in).
  final double pop;

  /// The hand's tilt, in radians.
  final double wave;

  /// How far the ring has spread, `0 → 1`; gone at both ends.
  final double ring;

  static const double _disc = AppSize.s76;
  static const double _ringGrowth = 0.75;
  static const double _ringAlpha = 0.5;
  static const double _ringWidth = AppSize.s2;
  static const String _hand = '\u{1F44B}';
  static const TextStyle _handStyle = TextStyle(fontSize: AppSize.font30);

  /// The hand turns around its wrist, low on the glyph.
  static const Alignment _wrist = Alignment(0.2, 0.7);
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
              child: DecoratedBox(
                decoration: _face,
                child: Center(
                  child: Transform.rotate(
                    angle: wave,
                    alignment: _wrist,
                    child: const Text(_hand, style: _handStyle),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
