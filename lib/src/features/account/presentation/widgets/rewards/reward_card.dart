import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/utils/failure_message.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../domain/entities/loyalty_reward.dart';
import 'reward_card_art.dart';
import 'reward_card_footer.dart';

/// One redemption tier: the art with its "KD x off" pill, the title and the
/// points it costs (or, when out of reach, a bar toward it and the points
/// still missing). Rises into place once, in cascade order.
///
/// Tapping a ready card spends its points on the current basket through the
/// app-global cart (`POST /v1/cart/loyalty`); a locked card is not tappable.
/// The tier the cart carries right now (`cart.loyalty.pointsApplied`) shows
/// an "Applied" chip, and tapping it again does nothing.
class RewardCard extends StatefulWidget {
  const RewardCard({
    super.key,
    required this.reward,
    required this.missingPoints,
    required this.balance,
    required this.entranceIndex,
    required this.floats,
    required this.onRedeemed,
  });

  final LoyaltyReward reward;

  /// Points still to earn; 0 = ready to redeem.
  final int missingPoints;

  /// The customer's points (a locked card's bar counts from it).
  final int balance;

  /// Position in the screen's cascade (ready cards first).
  final int entranceIndex;

  /// The gift may idle-float (the screen caps how many cards loop).
  final bool floats;

  /// Called once this tier was applied to the basket.
  final VoidCallback onRedeemed;

  /// Delay between two cards of the cascade.
  static const Duration cascadeStep = Duration(milliseconds: 70);

  /// Cards after this one start with the last delay (no long waits).
  static const int maxCascadeSteps = 5;

  bool get isLocked => missingPoints > 0;

  @override
  State<RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends State<RewardCard> {
  /// This card started the loyalty request the cart is running.
  bool _applying = false;

  Future<void> _redeem() async {
    final cart = context.read<CartCubit>();
    if (cart.state.isEmpty) {
      showJameiaSnackBar(context, 'loyalty.rewards_empty_cart'.tr());
      return;
    }
    final points = widget.reward.points;
    // Already on the basket: no second request, no second celebration.
    if (cart.state.cart.loyalty.pointsApplied == points) return;
    if (cart.state.isBusy || _applying) return;
    setState(() => _applying = true);
    final applied = await cart.applyLoyalty(points);
    // Transient: read it before anything else reaches the cart.
    final failure = cart.state.failure;
    if (!mounted) return;
    setState(() => _applying = false);
    if (applied) {
      Haptics.success();
      widget.onRedeemed();
    }
    showJameiaSnackBar(
      context,
      applied
          ? 'loyalty.reward_applied'.tr(namedArgs: {'points': '$points'})
          : failure?.localizedMessage ?? 'core.something_went_wrong'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final isLocked = widget.isLocked;
    final amount = Formatters.price(reward.valueKd);
    final delay =
        RewardCard.cascadeStep *
        widget.entranceIndex.clamp(0, RewardCard.maxCascadeSteps);
    return ScrollReveal(
      delay: delay,
      child: Semantics(
        button: !isLocked,
        enabled: !isLocked,
        child: PressScale(
          onTap: isLocked ? null : _redeem,
          enabled: !isLocked,
          child: BlocSelector<CartCubit, CartState, (bool, bool)>(
            selector: (state) => (
              state.busyAction == CartAction.loyalty,
              state.cart.loyalty.pointsApplied == reward.points,
            ),
            builder: (_, cart) {
              final (isRedeeming, isApplied) = cart;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RewardCardArt(
                    points: reward.points,
                    offLabel: 'loyalty.reward_off'.tr(
                      namedArgs: {'amount': amount},
                    ),
                    isLocked: isLocked,
                    isApplying: isRedeeming && _applying,
                    isApplied: isApplied,
                    floats: widget.floats,
                    popDelay: delay,
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Text(
                    'loyalty.reward_title'.tr(namedArgs: {'amount': amount}),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subheadingLarge.copyWith(
                      fontWeight: AppTextStyles.medium,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s6),
                  RewardCardFooter(
                    points: reward.points,
                    balance: widget.balance,
                    missingPoints: widget.missingPoints,
                    isApplied: isApplied,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
