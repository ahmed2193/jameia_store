import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';

/// The storefront's round "→": opens what a block advertises — its
/// collection, the campaign behind a banner. A lifted white disc with an ink
/// arrow that follows the reading direction. A [nudge] arrow gives two
/// small pushes forward every few seconds while it is on screen — the
/// campaign bands' call to tap.
class HomeArrowButton extends StatelessWidget {
  const HomeArrowButton({
    super.key,
    required this.onTap,
    required this.label,
    this.size = regularSize,
    this.nudge = false,
  });

  final VoidCallback onTap;

  /// What the arrow opens, for screen readers.
  final String label;
  final double size;

  /// Pushes forward now and then, to invite the tap.
  final bool nudge;

  /// Beside a section title.
  static const double regularSize = AppSize.s32;

  /// On a campaign band.
  static const double largeSize = AppSize.s40;

  /// The arrow's share of the disc.
  static const double _glyphShare = 0.55;

  /// How far a push goes.
  static const double _push = AppSpacing.s3;

  /// One nudge, then a still rest twice as long.
  static const Duration _nudge = Duration(milliseconds: 1200);
  static const Duration _nudgeRest = Duration(milliseconds: 2400);

  /// Two quick pushes: one burst, then the loop rests.
  static final Animatable<double> _pushes = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 1),
  ]).chain(CurveTween(curve: AppMotion.machEaseInOut));

  @override
  Widget build(BuildContext context) {
    // A Material directional glyph: it already mirrors under RTL.
    final glyph = Icon(
      Icons.arrow_forward_rounded,
      size: size * _glyphShare,
      color: AppColors.primaryText,
    );
    final forward = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    return Semantics(
      button: true,
      label: label,
      // The node replaces the child's semantics, its tap action included.
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: AppShadows.medium,
          ),
          child: nudge
              ? AmbientLoop.value(
                  period: _nudge,
                  rest: _nudgeRest,
                  valueBuilder: (context, t, glyph) => Transform.translate(
                    offset: Offset(forward * _push * _pushes.transform(t), 0),
                    child: glyph,
                  ),
                  child: glyph,
                )
              : glyph,
        ),
      ),
    );
  }
}
