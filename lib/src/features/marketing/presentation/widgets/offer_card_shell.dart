import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';

/// The flat card every offer sits on (and its loading bone): white, rounded,
/// a hairline edge, 16dp inside, a [leading] disc and the offer's text beside
/// it.
class OfferCardShell extends StatelessWidget {
  const OfferCardShell({super.key, required this.leading, required this.child});

  final Widget leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
