import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/thin_divider.dart';

/// The hairline between two blocks of the product page, inset to the 16 dp
/// gutters; with the blocks' own padding it leaves about 24 dp either side.
class PdpSectionDivider extends StatelessWidget {
  const PdpSectionDivider({super.key});

  static const double inset = AppSpacing.s16;
  static const double gap = AppSpacing.s8;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: inset,
        vertical: gap,
      ),
      child: ThinDivider(),
    );
  }
}
