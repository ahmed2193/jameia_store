import 'package:flutter/material.dart';

import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';

/// A label and its value on one line (price breakdowns, invoice facts).
/// Normal: grey meta label, ink value. [emphasized]: the bold total. [value]
/// is one widget — a `Text` or a `HeroMoneyText` — and picks its style up
/// from the surrounding [DefaultTextStyle].
class HeroSummaryLine extends StatelessWidget {
  const HeroSummaryLine({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final Widget value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasized ? AppTextStyles.groupTitle : AppTextStyles.meta,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Flexible(
            child: DefaultTextStyle.merge(
              style: emphasized
                  ? AppTextStyles.groupTitle
                  : AppTextStyles.label,
              textAlign: TextAlign.end,
              child: value,
            ),
          ),
        ],
      ),
    );
  }
}
