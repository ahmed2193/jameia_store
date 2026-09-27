import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/hero_input_decoration.dart';
import '../../../domain/entities/product_review_request.dart';
import '../../cubit/order_review_cubit.dart';

/// One optional comment, sent with every rated product: an outlined text
/// area in the page gutters. Typing rebuilds nothing but the field.
class ReviewCommentField extends StatefulWidget {
  const ReviewCommentField({super.key});

  @override
  State<ReviewCommentField> createState() => _ReviewCommentFieldState();
}

class _ReviewCommentFieldState extends State<ReviewCommentField> {
  late final OrderReviewCubit _cubit;
  late final TextEditingController _controller;

  static const int _lines = 4;

  @override
  void initState() {
    super.initState();
    // The page's cubit never changes under the field: read it once.
    _cubit = context.read<OrderReviewCubit>();
    _controller = TextEditingController(text: _cubit.state.draft.comment);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.select<OrderReviewCubit, bool>(
      (cubit) => cubit.state.isSubmitting,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.gutter,
      ),
      child: TextField(
        controller: _controller,
        enabled: !submitting,
        maxLines: _lines,
        maxLength: ProductReviewRequest.maxBodyLength,
        onChanged: _cubit.setComment,
        style: AppTextStyles.itemTitle,
        cursorColor: AppColors.primaryText,
        decoration: HeroInputDecoration.outlined(
          hintText: 'orders.review_comment_hint'.tr(),
        ),
      ),
    );
  }
}
