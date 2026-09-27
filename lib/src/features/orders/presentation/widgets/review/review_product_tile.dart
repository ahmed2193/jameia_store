import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_line_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_card_image.dart';
import '../../cubit/order_review_cubit.dart';
import 'review_star_bar.dart';

/// One product of the order: a 56 dp thumb with a hairline, the name, and
/// its stars. Rebuilds only when its own rating or lock changes.
class ReviewProductTile extends StatelessWidget {
  const ReviewProductTile({super.key, required this.line});

  /// The hairline drawn over the thumb (white packshots on the white page).
  static const BoxDecoration _thumbHairline = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
  );

  final OrderLineEntity line;

  @override
  Widget build(BuildContext context) {
    final (rating, locked) = context.select<OrderReviewCubit, (int, bool)>(
      (cubit) => (
        cubit.state.draft.ratingOf(line.productId),
        cubit.state.isSubmitting || cubit.state.draft.isSent(line.productId),
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: _thumbHairline,
            child: HeroCardImage(
              url: line.image,
              width: AppSize.s56,
              height: AppSize.s56,
              radius: AppRadius.card,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.nameFor(context.locale.languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.itemTitle,
                ),
                const SizedBox(height: AppSpacing.s4),
                ReviewStarBar(
                  enabled: !locked,
                  rating: rating,
                  onRate: (stars) => context.read<OrderReviewCubit>().rate(
                    line.productId,
                    stars,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
