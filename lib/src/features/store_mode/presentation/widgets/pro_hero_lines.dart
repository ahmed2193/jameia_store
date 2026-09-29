import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'pro_hero_tone.dart';

/// A hero's two big centred lines; the second carries the tone's accent
/// colour. The lines rise and fade in one after the other when this widget
/// mounts ([EntranceCascadeItem.single], one step apart) unless [entrance]
/// is false (new words cross-fading in over the old ones).
class ProHeroLines extends StatelessWidget {
  const ProHeroLines({
    super.key,
    required this.lineOne,
    required this.lineTwo,
    required this.tone,
    this.entrance = true,
  });

  final String lineOne;
  final String lineTwo;
  final ProHeroTone tone;

  /// The lines rise in on mount.
  final bool entrance;

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
          EntranceCascadeItem.single(
            play: entrance,
            index: 0,
            child: Text(
              lineOne,
              textAlign: TextAlign.center,
              style: style.copyWith(color: tone.lineOne),
            ),
          ),
          EntranceCascadeItem.single(
            play: entrance,
            index: 1,
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
