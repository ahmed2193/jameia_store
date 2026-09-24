import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_offer_progress_entity.dart';
import '../../../../../core/domain/entities/offer_reward_entity.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';

/// "Add X more to get Y" with a progress bar, one per offer the server
/// reports progress for.
class CartOfferProgressBanner extends StatelessWidget {
  const CartOfferProgressBanner({super.key, required this.progress});

  final CartOfferProgressEntity progress;

  /// The short, lower-case name of a reward, as this banner reads it
  /// ("free delivery", "10% off", "1.000 KD off"). The offers screen words
  /// the same rewards its own way — see `OfferTile`.
  static String _rewardText(OfferRewardEntity reward) => switch (reward.type) {
    OfferRewardType.freeDelivery => 'cart.reward_free_delivery'.tr(),
    OfferRewardType.percentageDiscount => 'cart.reward_percentage'.tr(
      namedArgs: {'percent': '${reward.percent}'},
    ),
    OfferRewardType.fixedDiscount => 'cart.reward_fixed'.tr(
      namedArgs: {'amount': Formatters.price(reward.amountKd)},
    ),
    OfferRewardType.freeProduct => 'cart.reward_free_product'.tr(),
    OfferRewardType.other => 'cart.reward_other'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final reward = _rewardText(progress.reward);
    final text = progress.isReached
        ? 'cart.offer_unlocked'.tr(namedArgs: {'reward': reward})
        : progress.isSubtotal
        ? 'cart.offer_progress_subtotal'.tr(
            namedArgs: {
              'amount': Formatters.price(progress.remainingKd),
              'reward': reward,
            },
          )
        : 'cart.offer_progress_items'.tr(
            namedArgs: {
              'count': '${progress.remainingValue}',
              'reward': reward,
            },
          );
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s8,
        AppSpacing.s12,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.freeDeliveryBg,
        borderRadius: BorderRadius.circular(AppRadius.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: AppTextStyles.medium,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r7),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress.fraction),
              duration: MotionGuard.duration(context, AppMotion.medium),
              curve: AppMotion.standard,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: AppSize.s4,
                backgroundColor: AppColors.white,
                color: AppColors.freeDelivery,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
