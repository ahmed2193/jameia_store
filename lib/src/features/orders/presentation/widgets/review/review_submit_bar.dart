import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/blocked_tap_shake.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../cubit/order_review_cubit.dart';

/// The pinned submit pill of the review page. A tap before any star is set
/// shakes it (the hint above the list says what to do); while it sends, the
/// page's busy overlay holds the screen and the pill keeps its label. It
/// owns the submit selects, so a rating that flips "can submit" rebuilds
/// this bar only — not the product list.
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
    return HeroBottomBar(
      child: BlockedTapShake(
        blocked: !canSubmit && !submitting && !submitted,
        child: HeroSubmitButton(
          label: 'orders.review_submit'.tr(),
          holding: submitting || submitted,
          enabled: canSubmit,
          onPressed: () => context.read<OrderReviewCubit>().submit(),
        ),
      ),
    );
  }
}
