import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/hero_section_header.dart';

/// The heading above the history ("Transactions", "Points history"): the
/// shared section header, tight above the first day.
class LedgerSectionTitle extends StatelessWidget {
  const LedgerSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return HeroSectionHeader(
      title: text,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.section,
        AppSpacing.gutter,
        AppSpacing.s2,
      ),
    );
  }
}
