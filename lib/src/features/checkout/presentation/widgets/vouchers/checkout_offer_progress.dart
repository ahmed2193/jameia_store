import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/checkout_offer_card.dart';

/// How far a locked offer is: a bar that glides to the basket's progress
/// (in its own repaint layer; static on the first build) and what is still
/// missing — "Add KD x more to unlock" / "Add N more from {name}", or "…to
/// qualify" for an offer that cannot be combined with the others (the
/// basket only qualifies for it; it never adds on top).
class CheckoutOfferProgress extends StatelessWidget {
  const CheckoutOfferProgress({super.key, required this.card});

  final CheckoutOfferCard card;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  static String _missing(CheckoutOfferCard card) {
    if (card.remainingIsFils) {
      final amount = {'amount': Formatters.price(card.remainingKd)};
      return card.qualifiesOnly
          ? 'checkout.offer_add_amount_qualify'.tr(namedArgs: amount)
          : 'checkout.offer_add_amount'.tr(namedArgs: amount);
    }
    final count = {
      'count': '${card.remainingValue}',
      'name': card.contextName ?? card.name,
    };
    return card.qualifiesOnly
        ? 'checkout.offer_add_count_qualify'.tr(namedArgs: count)
        : 'checkout.offer_add_count'.tr(namedArgs: count);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: card.fraction),
              duration: MotionGuard.duration(context, AppMotion.slow),
              curve: AppMotion.emphasizedDecelerate,
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: AppSize.s5,
                borderRadius: _radius,
                backgroundColor: AppColors.smallBackground,
                color: AppColors.accent1,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            const HeroIcon(
              HeroIcons.info,
              size: AppSize.s16,
              color: AppColors.accent1,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                _missing(card),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
