import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'pro_hero_parallax.dart';

/// The Jameia bag standing in the hero's dome: it rises and fades in once,
/// then floats gently and lags a little behind the page while it scrolls.
/// [height] is the dome's height (caps the decoded image size).
class ProHeroBag extends StatelessWidget {
  const ProHeroBag({super.key, required this.height});

  static const double _rise = AppSize.s24;
  static const double _floatAmplitude = AppSize.s6;

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s64,
        AppSpacing.s40,
        AppSpacing.s64,
        AppSpacing.s16,
      ),
      child: ProHeroParallax(
        child: FloatLoop(
          amplitude: _floatAmplitude,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: MotionGuard.duration(context, AppMotion.drawOn),
            curve: AppMotion.emphasizedDecelerate,
            child: Image.asset(
              JameiaAssets.jameiaBag,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              cacheWidth: context.cacheCapFor(height),
              excludeFromSemantics: true,
            ),
            builder: (context, shown, child) => Opacity(
              opacity: shown.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, _rise * (1 - shown)),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
