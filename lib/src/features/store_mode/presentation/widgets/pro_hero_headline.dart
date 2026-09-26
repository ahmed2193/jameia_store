import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/pro_membership.dart';
import 'pro_hero_tone.dart';

/// The hero's two big centred lines, worded for the plan's billing interval;
/// the second line carries the tone's accent colour. The lines rise and fade
/// in one after the other when this widget mounts — key it by plan so a new
/// plan re-plays the stagger.
class ProHeroHeadline extends StatelessWidget {
  const ProHeroHeadline({
    super.key,
    required this.interval,
    required this.tone,
  });

  static const Duration _lineStagger = Duration(milliseconds: 80);

  /// Each line rises by this share of its own height.
  static const Offset _rise = Offset(0, 0.35);

  final ProBillingInterval interval;
  final ProHeroTone tone;

  @override
  Widget build(BuildContext context) {
    final (lineOne, lineTwo) = switch (interval) {
      ProBillingInterval.month => (
        'pro.hero_month_line1',
        'pro.hero_month_line2',
      ),
      ProBillingInterval.year => ('pro.hero_year_line1', 'pro.hero_year_line2'),
      ProBillingInterval.other => (
        'pro.hero_other_line1',
        'pro.hero_other_line2',
      ),
    };
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
              lineOne.tr(),
              textAlign: TextAlign.center,
              style: style.copyWith(color: tone.lineOne),
            ),
          ),
          StaggerEntrance(
            index: 1,
            stagger: _lineStagger,
            beginOffset: _rise,
            child: Text(
              lineTwo.tr(),
              textAlign: TextAlign.center,
              style: style.copyWith(color: tone.lineTwo),
            ),
          ),
        ],
      ),
    );
  }
}
