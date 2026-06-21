import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Small rating pill: ★ 4.8 in KeeTa's bold digit style.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.count, this.size = 12});

  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: AppColors.warn),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: AppTextStyles.captionLarge.copyWith(
                fontWeight: AppTextStyles.bold, color: AppColors.primaryText)),
        if (count != null) ...[
          const SizedBox(width: 2),
          Text('($count)',
              style: AppTextStyles.captionSmall
                  .copyWith(color: AppColors.tertiaryText)),
        ],
      ],
    );
  }
}

/// Section header row: bold title + optional trailing "see all" arrow.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.padding =
        const EdgeInsetsDirectional.fromSTEB(AppSpacing.pageMargin, AppSpacing.s16, AppSpacing.pageMargin, AppSpacing.s8),
  });

  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: AppTextStyles.headingLarge
                    .copyWith(fontWeight: AppTextStyles.bold)),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 20, color: AppColors.secondaryText),
            ),
        ],
      ),
    );
  }
}

/// Colored promo / tag chip (free delivery, % off, etc.).
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.bg = AppColors.freeDeliveryBg,
    this.fg = AppColors.freeDelivery,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 2),
          ],
          Text(label,
              style: AppTextStyles.captionSmall
                  .copyWith(color: fg, fontWeight: AppTextStyles.medium)),
        ],
      ),
    );
  }
}

/// Thin divider matching the token divider color.
class ThinDivider extends StatelessWidget {
  const ThinDivider({super.key, this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) => Divider(
      height: 1, thickness: 1, color: AppColors.divider, indent: indent, endIndent: indent);
}
