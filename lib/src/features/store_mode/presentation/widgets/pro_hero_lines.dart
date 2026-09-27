import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'pro_hero_tone.dart';

/// A hero's two big centred lines; the second carries the tone's accent
/// colour. The lines rise and fade in one after the other when this widget
/// mounts — key it by what it says so new words re-play the stagger.
class ProHeroLines extends StatelessWidget {
  const ProHeroLines({
    super.key,
    required this.lineOne,
    required this.lineTwo,
    required this.tone,
  });

  static const Duration _lineStagger = Duration(milliseconds: 80);

  /// Each line rises by this share of its own height.
  static const Offset _rise = Offset(0, 0.35);

  final String lineOne;
  final String lineTwo;
  final ProHeroTone tone;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.displayLarge.copyWith(
      fontSize: AppSize.font40,
      height: AppSize.lh1_1,
      fontWeight: AppTextStyles.bold,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      child: Column(
        children: [
          StaggerEntrance(
            index: 0,
            stagger: _lineStagger,
            beginOffset: _rise,
            child: Text(
              lineOne,
              textAlign: TextAlign.center,
              style: style.copyWith(color: tone.lineOne),
            ),
          ),
          StaggerEntrance(
            index: 1,
            stagger: _lineStagger,
            beginOffset: _rise,
            child: Text(
              lineTwo,
              textAlign: TextAlign.center,
              style: style.copyWith(color: tone.lineTwo),
            ),
          ),
        ],
      ),
    );
  }
}
