import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/rating_badge.dart';
import '../cubit/product_reviews_cubit.dart';
import '../cubit/product_reviews_state.dart';
import 'pdp_review_tile.dart';
import 'pdp_section_card.dart';

/// Reviews of the product: the rating summary, the reviews loaded so far and
/// "Show more". Its own loader / error / empty states live INSIDE the card, so
/// a reviews failure never touches the rest of the product page.
class PdpReviewsSection extends StatelessWidget {
  const PdpReviewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PdpSectionCard(
      title: 'product.reviews'.tr(),
      child: BlocBuilder<ProductReviewsCubit, ProductReviewsState>(
        builder: (context, state) {
          final cubit = context.read<ProductReviewsCubit>();
          switch (state.status) {
            case ProductReviewsStatus.initial:
            case ProductReviewsStatus.loading:
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: AppLoader(),
              );
            case ProductReviewsStatus.error:
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      state.failure?.localizedMessage ??
                          'product.reviews_failed'.tr(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  TextButton(onPressed: cubit.load, child: Text('retry'.tr())),
                ],
              );
            case ProductReviewsStatus.loaded:
              if (state.isEmpty) {
                return Text(
                  'product.no_reviews'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                );
              }
              final reviews = state.reviews;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RatingBadge(rating: reviews.ratingAverage),
                      const SizedBox(width: AppSpacing.s6),
                      Text(
                        'product.based_on_reviews'.tr(
                          namedArgs: {'count': '${reviews.ratingCount}'},
                        ),
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  for (final review in reviews.reviews)
                    PdpReviewTile(key: ValueKey(review.id), review: review),
                  if (state.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.s8),
                      child: AppLoader(),
                    )
                  else if (reviews.hasMore)
                    Center(
                      child: TextButton(
                        onPressed: cubit.loadMore,
                        child: Text(
                          state.loadMoreFailed
                              ? 'retry'.tr()
                              : 'product.show_more_reviews'.tr(),
                        ),
                      ),
                    ),
                ],
              );
          }
        },
      ),
    );
  }
}
