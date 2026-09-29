import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/widgets/state_art.dart';

/// The rating card once the review went through: the Hero "done" sticker
/// ([HeroAssets.stateSuccess], card size) fades in with the thanks (read out
/// as it appears). The API keeps no "rated" flag
/// on an order, so this lasts while the order page is open.
class TrackingRateThanks extends StatelessWidget {
  const TrackingRateThanks({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StateArt(asset: HeroAssets.stateSuccess, compact: true),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'orders.rate_thanks_title'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'orders.rate_thanks_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.meta,
          ),
        ],
      ),
    );
  }
}
