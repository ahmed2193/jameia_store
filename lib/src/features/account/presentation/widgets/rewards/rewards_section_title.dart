import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/widgets/hero_section_header.dart';

/// The heading above a group of reward cards ("Ready to redeem"): the shared
/// section header; it rises in once, when it first scrolls into view.
class RewardsSectionTitle extends StatelessWidget {
  const RewardsSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      child: HeroSectionHeader(
        title: text,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.gutter,
          AppSpacing.section,
          AppSpacing.gutter,
          AppSpacing.s16,
        ),
      ),
    );
  }
}
