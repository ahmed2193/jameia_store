import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// Burnt-orange pill at the top of a reward card: a gift glyph + "KD 0.100
/// off". The label never ellipsizes (a cut amount reads as another value):
/// on a narrow card or a large text scale it shrinks to fit instead.
class RewardOffPill extends StatelessWidget {
  const RewardOffPill({super.key, required this.label});

  final String label;

  /// orange.c12 — the white 12 px bold label reads at 4.9:1 on it (the
  /// brighter `kHeroPillPin` gave 3:1).
  static const int _fillShade = 11;
  static final Color _fill = AppColors.orange[_fillShade];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.card_giftcard_rounded,
              size: AppSize.s14,
              color: AppColors.white,
            ),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTextStyles.captionLarge.copyWith(
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
