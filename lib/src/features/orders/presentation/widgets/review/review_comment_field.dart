import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/product_review_request.dart';
import '../../cubit/order_review_cubit.dart';

/// One optional comment, sent with every rated product.
class ReviewCommentField extends StatefulWidget {
  const ReviewCommentField({super.key});

  @override
  State<ReviewCommentField> createState() => _ReviewCommentFieldState();
}

class _ReviewCommentFieldState extends State<ReviewCommentField> {
  late final TextEditingController _controller;

  static const int _lines = 4;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OrderReviewCubit>().state.draft.comment,
    );
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
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: TextField(
        controller: _controller,
        enabled: !submitting,
        maxLines: _lines,
        maxLength: ProductReviewRequest.maxBodyLength,
        onChanged: context.read<OrderReviewCubit>().setComment,
        decoration: InputDecoration(
          hintText: 'orders.review_comment_hint'.tr(),
        ),
      ),
    );
  }
}
