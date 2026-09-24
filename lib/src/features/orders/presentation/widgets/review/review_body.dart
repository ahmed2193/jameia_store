import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../cubit/order_review_cubit.dart';
import 'review_comment_field.dart';
import 'review_product_tile.dart';

/// The delivered order's products with stars, one comment, and submit.
class ReviewBody extends StatelessWidget {
  const ReviewBody({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final canSubmit = context.select<OrderReviewCubit, bool>(
      (cubit) => cubit.state.canSubmit,
    );
    final submitting = context.select<OrderReviewCubit, bool>(
      (cubit) => cubit.state.isSubmitting,
    );
    return Column(
      children: [
        Expanded(
          // Lazy slivers: a long order does not build (and fetch the picture
          // of) every product before the first frame.
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Text(
                    'orders.review_rate_hint'.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ),
              DecoratedSliver(
                decoration: const BoxDecoration(color: AppColors.white),
                sliver: SliverList.separated(
                  itemCount: order.lines.length,
                  separatorBuilder: (_, _) =>
                      const ThinDivider(indent: AppSpacing.s16),
                  itemBuilder: (_, index) => ReviewProductTile(
                    key: ValueKey<String>(order.lines[index].key),
                    line: order.lines[index],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s8)),
              const SliverToBoxAdapter(
                child: ColoredBox(
                  color: AppColors.white,
                  child: ReviewCommentField(),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: AppButton(
              label: 'orders.review_submit'.tr(),
              radius: AppRadius.r2,
              loading: submitting,
              enabled: canSubmit,
              onPressed: () => context.read<OrderReviewCubit>().submit(),
            ),
          ),
        ),
      ],
    );
  }
}
