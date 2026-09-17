import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/order.dart';
import 'chat_icon_button.dart';
import 'order_pill_button.dart';
import 'review_stars.dart';

class OrderActions extends StatelessWidget {
  const OrderActions({
    super.key,
    required this.order,
    required this.onTrack,
    required this.onChat,
    required this.onCancelOrder,
    required this.onReview,
    required this.onReorder,
    required this.onRefundStatus,
  });

  final OrderEntity order;
  final VoidCallback onTrack;
  final VoidCallback onChat;
  final VoidCallback onCancelOrder;
  final VoidCallback onReview;
  final VoidCallback onReorder;
  final VoidCallback onRefundStatus;

  @override
  Widget build(BuildContext context) {
    if (order.isActive) {
      // Bundle: active card row — [chat-icon][cancel-text]···[Track order pill]
      // chat icon = 40×40dp rounded-square (r13), cancel = text red, track = filled yellow pill
      return Row(
        children: [
          // ── Rider IM chat icon (40×40dp, #F0F1F5 bg, r13) ──────────────
          ChatIconButton(onPressed: onChat),
          const SizedBox(width: AppSpacing.s8),
          // ── Cancel order (Jameia-Regular 14dp error red, no bg) ──────────
          GestureDetector(
            onTap: onCancelOrder,
            child: Text(
              'orders.cancel_order'.tr(),
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.error,
                fontWeight: AppTextStyles.regular,
              ),
            ),
          ),
          const Spacer(),
          // ── Track order (yellow pill, 48dp height, 24dp radius) ─────────
          OrderPillButton(
            label: 'orders.track_order'.tr(),
            icon: JameiaIcons.delivery,
            filled: true,
            onPressed: onTrack,
          ),
        ],
      );
    }
    // Cancelled → refund lifecycle jump (Jameia order_list → refund_detail)
    if (order.status == 'cancelled') {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: OrderPillButton(
          label: 'orders.refund_status'.tr(),
          icon: JameiaIcons.refund,
          filled: true,
          onPressed: onRefundStatus,
        ),
      );
    }
    // Completed → tappable review-star row + [Review outline] + [Reorder filled]
    // Bundle: completed cards surface a `order_evaluate_star*` rating row that
    // routes into order_review on tap. We render 5 stars (JameiaIcons.star) and
    // keep the Review pill as the explicit CTA fallback.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewStars(onTap: onReview),
        const SizedBox(height: AppSpacing.s12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OrderPillButton(
              label: 'orders.review'.tr(),
              icon: JameiaIcons.star,
              onPressed: onReview,
            ),
            const SizedBox(width: AppSpacing.s8),
            OrderPillButton(
              label: 'orders.reorder'.tr(),
              icon: JameiaIcons.orderAgain,
              filled: true,
              onPressed: onReorder,
            ),
          ],
        ),
      ],
    );
  }
}
