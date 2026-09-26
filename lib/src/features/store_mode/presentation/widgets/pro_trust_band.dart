import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import 'pro_trust_line.dart';

/// The trust line on its own soft lavender band that spans the whole width
/// of the bottom bar, edge to edge, right under the account strip.
/// [termsOnly] keeps just the terms link (a member has nothing to join).
class ProTrustBand extends StatelessWidget {
  const ProTrustBand({super.key, this.termsOnly = false});

  final bool termsOnly;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.accentVioletLight,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s4,
        ),
        child: ProTrustLine(termsOnly: termsOnly),
      ),
    );
  }
}
