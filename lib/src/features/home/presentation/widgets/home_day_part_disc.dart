import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_greeting.dart';
import 'home_loop.dart';

/// The round sky beside the greeting — a sun in the morning and afternoon, a
/// setting sun in the evening, a moon at night — that sways now and then, as
/// if it were hanging in a breeze.
class HomeDayPartDisc extends StatelessWidget {
  const HomeDayPartDisc({super.key, required this.dayPart});

  final HomeDayPart dayPart;

  static const double size = AppSize.s40;
  static const double _glyph = AppSize.s22;

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
        Icons.wb_sunny_rounded,
        AppColors.accent3,
        AppColors.accent4Light,
      ),
      HomeDayPart.afternoon => (
        Icons.light_mode_rounded,
        AppColors.accent3Dark,
        AppColors.accent3Light,
      ),
      HomeDayPart.evening => (
        Icons.wb_twilight_rounded,
        AppColors.accent1,
        AppColors.accent1Light,
      ),
      HomeDayPart.night => (
        Icons.nights_stay_rounded,
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
        child: HomeLoop(
          period: AppMotion.sheen ~/ 2,
          rest: AppMotion.sheen,
          builder: (context, t, child) =>
              Transform.rotate(angle: _sway.transform(t), child: child),
          child: Icon(icon, size: _glyph, color: ink),
        ),
      ),
    );
  }
}
