import 'package:flutter/material.dart';

// TODO(P2.9-boundary): CartItem is the cart feature's core line type (its
// display getters resolve locale live); this checkout row renders it directly,
// so the core DTO is kept at this cross-feature boundary rather than remapped.
import '../../../../../core/data/models/models.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/core_widgets.dart';

class ItemRow extends StatelessWidget {
  const ItemRow({super.key, required this.line});
  final CartItem line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      child: Row(
        children: [
          // Product thumbnail — 68×68 (Jameia item tiles); variant image if any.
          JameiaCardImage(
            url: line.displayImage,
            width: 68,
            height: 68,
            radius: AppRadius.card,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge,
                ),
                if (line.product.desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line.product.desc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    PriceText(price: line.lineTotal, size: 14),
                    const Spacer(),
                    // qty badge
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.s8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.smallBackground,
                        borderRadius: BorderRadius.circular(AppRadius.r5),
                      ),
                      child: Text(
                        '×${line.qty}',
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                          fontWeight: AppTextStyles.medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
