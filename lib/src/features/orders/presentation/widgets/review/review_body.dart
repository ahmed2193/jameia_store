import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/widgets/jameia_section_header.dart';
import '../../../../../core/widgets/thin_divider.dart';
import 'review_comment_field.dart';
import 'review_product_tile.dart';
import 'review_submit_bar.dart';

/// The delivered order's products with stars, one comment, and the submit
/// pill pinned in the bottom bar. Reads no state itself: each tile selects
/// its own stars and the bar its own submit state.
class ReviewBody extends StatelessWidget {
  const ReviewBody({super.key, required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final lines = order.lines;
    final indexOf = <String, int>{
      for (var i = 0; i < lines.length; i++) lines[i].key: i,
    };
    return Column(
      children: [
        Expanded(
          // Lazy slivers: a long order does not build (and fetch the picture
          // of) every product before the first frame.
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.gutter,
                    AppSpacing.s16,
                    AppSpacing.gutter,
                    AppSpacing.s8,
                  ),
                  child: Text(
                    'orders.review_rate_hint'.tr(),
                    style: AppTextStyles.meta,
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: lines.length,
                findItemIndexCallback: (key) =>
                    key is ValueKey<String> ? indexOf[key.value] : null,
                separatorBuilder: (_, _) =>
                    const ThinDivider(indent: AppSpacing.gutter),
                itemBuilder: (_, index) => ReviewProductTile(
                  key: ValueKey<String>(lines[index].key),
                  line: lines[index],
                ),
              ),
              SliverToBoxAdapter(
                child: JameiaSectionHeader(
                  title: 'orders.review_comment_title'.tr(),
                  titleStyle: AppTextStyles.groupTitle,
                ),
              ),
              const SliverToBoxAdapter(child: ReviewCommentField()),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.section),
              ),
            ],
          ),
        ),
        const ReviewSubmitBar(),
      ],
    );
  }
}
