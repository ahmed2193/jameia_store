import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/utils/formatters.dart';
import 'pro_hero_arch.dart';
import 'pro_hero_lines.dart';
import 'pro_hero_tone.dart';
import 'pro_wave_clipper.dart';

/// A member's hero, in place of the plan tabs and the plan's hero: the bold
/// Pro band with its wavy edges, "You're Pro / Perks are on" — once
/// cancelled "Still Pro / until 17 Oct" — rising in line by line, and the
/// Hero bag in its dome drawing itself, as on the paywall.
class ProMemberHero extends StatelessWidget {
  const ProMemberHero({super.key, required this.membership});

  static const ProHeroTone _tone = ProHeroTone.bold;

  final ProMembershipEntity membership;

  @override
  Widget build(BuildContext context) {
    final date = Formatters.dayMonth(
      context.locale.languageCode,
      membership.periodEnd,
    );
    final ending = membership.standing == ProStanding.ending;
    final (lineOne, lineTwo) = ending && date.isNotEmpty
        ? (
            'pro.ending_hero_line1'.tr(),
            'pro.ending_hero_line2'.tr(namedArgs: {'date': date}),
          )
        : ('pro.member_hero_line1'.tr(), 'pro.member_hero_line2'.tr());
    return ClipPath(
      clipper: const ProWaveClipper(),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: _tone.bandGradient),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s40),
            ProHeroLines(
              key: ValueKey<ProStanding>(membership.standing),
              lineOne: lineOne,
              lineTwo: lineTwo,
              tone: _tone,
            ),
            const SizedBox(height: AppSpacing.s20),
            const ProHeroArch(tone: _tone),
          ],
        ),
      ),
    );
  }
}
