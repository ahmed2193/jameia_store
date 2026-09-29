import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/pro_membership.dart';
import 'pro_hero_lines.dart';
import 'pro_hero_tone.dart';

/// The plan hero's two big centred lines, worded for the plan's billing
/// interval (see [ProHeroLines]). The lines rise in when the hero first
/// shows ([entrance]); a later plan's words cross-fade in instead (its host
/// switches them), so a plan switch never replays the entrance.
class ProHeroHeadline extends StatelessWidget {
  const ProHeroHeadline({
    super.key,
    required this.interval,
    required this.tone,
    this.entrance = true,
  });

  final ProBillingInterval interval;
  final ProHeroTone tone;

  /// The lines rise in on mount.
  final bool entrance;

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
    return ProHeroLines(
      lineOne: lineOne.tr(),
      lineTwo: lineTwo.tr(),
      tone: tone,
      entrance: entrance,
    );
  }
}
