import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/order_review_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../../../core/widgets/hero_surface_card.dart';
import '../../cubit/order_tracking_cubit.dart';
import 'tracking_rate_star.dart';
import 'tracking_rate_thanks.dart';

/// "How was your order?" on a delivered order: five stars; a tap opens the
/// review of the order's products with that many stars already chosen (the
/// customer can still change each one). A review that went through turns
/// the card into its thanks (fade through, the card easing to its new
/// height); the order is read again on the way back.
class TrackingRateCard extends StatefulWidget {
  const TrackingRateCard({super.key, required this.orderId});

  final String orderId;

  @override
  State<TrackingRateCard> createState() => _TrackingRateCardState();
}

class _TrackingRateCardState extends State<TrackingRateCard> {
  static const int _stars = 5;

  bool _rated = false;

  Future<void> _rate(int stars) async {
    Haptics.pick();
    final cubit = context.read<OrderTrackingCubit>();
    final sent = await context.push<bool>(
      Routes.orderReview,
      extra: OrderReviewArgs(orderId: widget.orderId, rating: stars),
    );
    if (!mounted) return;
    if (sent == true) setState(() => _rated = true);
    await cubit.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s16,
        AppSpacing.gutter,
        0,
      ),
      child: HeroSurfaceCard(
        tone: HeroSurfaceTone.brand,
        // The card keeps the page's width whatever it holds: the reveal
        // around it lets it shrink to its content (the thanks is narrow).
        child: SizedBox(
          width: double.infinity,
          // One height move while the stars cross-fade into the thanks
          // (not an AnimatedSize around a switcher: that moves twice).
          child: SizeFadeSwitcher(
            stateKey: _rated,
            alignment: AlignmentDirectional.topCenter,
            child: _rated
                ? const TrackingRateThanks()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'orders.rate_title'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.headingLarge,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        'orders.rate_subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.meta,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 1; i <= _stars; i++)
                            TrackingRateStar(
                              value: i,
                              max: _stars,
                              onPressed: () => _rate(i),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
