import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// Colour pairs of a [JameiaTag] (every pair meets AA for bold 12).
enum JameiaTagTone {
  /// Deep brand green, white text — deals, "off" amounts.
  brand(AppColors.brandDeep, AppColors.white),

  /// Green wash, deep green text — in progress, applied, free.
  brandSoft(AppColors.brandLightBg, AppColors.brandDeep),

  /// Muted grey, ink text — neutral facts.
  neutral(AppColors.smallBackground, AppColors.primaryText),

  /// Red wash, deep red text — cancelled, failed.
  error(AppColors.errorBg, AppColors.errorDeep);

  const JameiaTagTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Small flat tag: bold 12 text, an optional leading icon, one of
/// [JameiaTagTone]'s colour pairs; a pill when [pill] is set.
class JameiaTag extends StatelessWidget {
  const JameiaTag({
    super.key,
    required this.label,
    this.icon,
    this.tone = JameiaTagTone.brandSoft,
    this.pill = false,
  });

  final String label;
  final IconData? icon;
  final JameiaTagTone tone;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(
          pill ? AppRadius.pill : AppRadius.chip,
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSize.s14, color: tone.foreground),
              const SizedBox(width: AppSpacing.s4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.tag.copyWith(color: tone.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
