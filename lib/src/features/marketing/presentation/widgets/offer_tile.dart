import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/widgets/countdown_chip.dart';
import 'offer_card_shell.dart';
import 'offer_reward_chip.dart';
import 'offer_reward_disc.dart';
import 'offer_terms.dart';
import 'offer_title.dart';

/// One automatic cart promotion as a flat Hero card: a tinted disc for
/// the kind of reward, the backend's name and description, the reward in a
/// lime chip, a running clock when the offer ends within
/// [countdownWindow], and the small print ([OfferTerms]).
class OfferTile extends StatelessWidget {
  const OfferTile({super.key, required this.offer, this.clock = DateTime.now});

  final OfferEntity offer;

  /// What time it is; a test sets it.
  final DateTime Function() clock;

  /// An offer ending sooner than this counts down; a later end date reads
  /// as a day in the small print.
  static const Duration countdownWindow = Duration(days: 1);
  static const int _descriptionLines = 2;

  @override
  Widget build(BuildContext context) {
    final endsAt = offer.endsAt;
    final left = endsAt?.difference(clock());
    final countsDown =
        left != null && left > Duration.zero && left <= countdownWindow;
    final hasReward = offer.rewardType != OfferRewardType.other;
    return Semantics(
      container: true,
      child: OfferCardShell(
        leading: OfferRewardDisc(type: offer.rewardType),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            OfferTitle(offer: offer),
            if (offer.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                offer.description,
                maxLines: _descriptionLines,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
            if (hasReward || countsDown) ...[
              const SizedBox(height: AppSpacing.s12),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (hasReward) OfferRewardChip(offer: offer),
                  if (countsDown)
                    // The chip's clock cannot wrap: on a narrow card or a
                    // large text size it shrinks instead of overflowing.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: CountdownChip(endsAt: endsAt!, clock: clock),
                    ),
                ],
              ),
            ],
            OfferTerms(offer: offer, showsEndDate: !countsDown),
          ],
        ),
      ),
    );
  }
}
