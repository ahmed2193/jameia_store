import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/blocked_tap_shake.dart';
import '../../../../../core/widgets/jameia_bottom_bar.dart';
import '../../../../../core/widgets/jameia_submit_button.dart';
import '../../cubit/order_review_cubit.dart';

/// The pinned submit pill of the review page. A tap before any star is set
/// shakes it (the hint above the list says what to do); submitting shows
/// the loader, then a check while the page closes. It owns the submit
/// selects, so a rating that flips "can submit" rebuilds this bar only —
/// not the product list.
class ReviewSubmitBar extends StatelessWidget {
  const ReviewSubmitBar({super.key});

  @override
  Widget build(BuildContext context) {
    final canSubmit = context.select<OrderReviewCubit, bool>(
      (cubit) => cubit.state.canSubmit,
    );
    final submitting = context.select<OrderReviewCubit, bool>(
      (cubit) => cubit.state.isSubmitting,
    );
    final submitted = context.select<OrderReviewCubit, bool>(
      (cubit) => cubit.state.submitted,
    );
    return JameiaBottomBar(
      child: BlockedTapShake(
        blocked: !canSubmit && !submitting && !submitted,
        child: JameiaSubmitButton(
          label: 'orders.review_submit'.tr(),
          loading: submitting,
          success: submitted,
          successLabel: 'orders.review_thanks'.tr(),
          enabled: canSubmit,
          onPressed: () => context.read<OrderReviewCubit>().submit(),
        ),
      ),
    );
  }
}
