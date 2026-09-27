import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/thin_divider.dart';
import '../cubit/product_reviews_cubit.dart';
import '../cubit/product_reviews_state.dart';
import 'pdp_review_tile.dart';
import 'pdp_reviews_summary.dart';
import 'pdp_section.dart';

/// Reviews of the product, flat: the rating summary, the reviews loaded so
/// far split by hairlines, and an outlined "Show more". Its own loader /
/// error / empty states live INSIDE the block, so a reviews failure never
/// touches the rest of the product page; offline it says "No connection"
/// and asks again by itself when the connection returns.
class PdpReviewsSection extends StatelessWidget {
  const PdpReviewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PdpSection(
      title: 'product.reviews'.tr(),
      child: ReconnectRefresh(
        onReconnected: () =>
            context.read<ProductReviewsCubit>().onReconnected(),
        child: BlocBuilder<ProductReviewsCubit, ProductReviewsState>(
          builder: (context, state) {
            final cubit = context.read<ProductReviewsCubit>();
            final muted = AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryText,
            );
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
                      child: Text(switch (state.failure) {
                        NetworkFailure() =>
                          'connectivity.offline_state_title'.tr(),
                        final failure? => failure.localizedMessage,
                        null => 'product.reviews_failed'.tr(),
                      }, style: muted),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    AppOutlineButton(
                      label: 'retry'.tr(),
                      onPressed: cubit.load,
                    ),
                  ],
                );
              case ProductReviewsStatus.loaded:
                if (state.isEmpty) {
                  return Text('product.no_reviews'.tr(), style: muted);
                }
                final reviews = state.reviews;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PdpReviewsSummary(
                      average: reviews.ratingAverage,
                      count: reviews.ratingCount,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    for (final review in reviews.reviews) ...[
                      const ThinDivider(),
                      PdpReviewTile(key: ValueKey(review.id), review: review),
                    ],
                    if (state.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.s8),
                        child: AppLoader(),
                      )
                    else if (reviews.hasMore) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Center(
                        child: AppOutlineButton(
                          label: state.loadMoreFailed
                              ? 'retry'.tr()
                              : 'product.show_more_reviews'.tr(),
                          onPressed: cubit.loadMore,
                        ),
                      ),
                    ],
                  ],
                );
            }
          },
        ),
      ),
    );
  }
}
