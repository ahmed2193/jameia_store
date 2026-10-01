import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/ambient_loop.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import '../../domain/entities/home_greeting.dart';

/// The round sky beside the greeting — a sun in the morning and afternoon, a
/// setting sun in the evening, a moon at night — that sways now and then, as
/// if it were hanging in a breeze.
class HomeDayPartDisc extends StatelessWidget {
  const HomeDayPartDisc({super.key, required this.dayPart});

  final HomeDayPart dayPart;

  static const double size = AppSize.s40;
  static const double _glyph = AppSize.s22;

  /// One sway of the glyph, then a still rest twice as long.
  static const Duration _swayLength = Duration(milliseconds: 1800);
  static const Duration _swayRest = Duration(milliseconds: 3600);

  /// One sway to either side and back.
  static final Animatable<double> _sway = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 0.16), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.16, end: -0.12), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -0.12, end: 0), weight: 1),
  ]).chain(CurveTween(curve: AppMotion.machEaseInOut));

  @override
  Widget build(BuildContext context) {
    final (icon, ink, plate) = switch (dayPart) {
      HomeDayPart.morning => (
        HeroIcons.sun,
        AppColors.accent3,
        AppColors.accent4Light,
      ),
      HomeDayPart.afternoon => (
        HeroIcons.sun,
        AppColors.accent3Dark,
        AppColors.accent3Light,
      ),
      HomeDayPart.evening => (
        HeroIcons.sunrise,
        AppColors.accent1,
        AppColors.accent1Light,
      ),
      HomeDayPart.night => (
        HeroIcons.moon,
        AppColors.martGreenDark,
        AppColors.martGreenLight,
      ),
    };
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: plate, shape: BoxShape.circle),
        child: AmbientLoop.value(
          period: _swayLength,
          rest: _swayRest,
          valueBuilder: (context, t, child) =>
              Transform.rotate(angle: _sway.transform(t), child: child),
          child: HeroIcon(icon, size: _glyph, color: ink),
        ),
      ),
    );
  }
}
