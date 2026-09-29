import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_assets.dart';
import '../../../../core/widgets/state_art.dart';

/// Friendly empty state of a coupon list: the Hero "no offers" tickets
/// ([HeroAssets.emptyCoupons], the same art on every tab — the [message]
/// changes), fading in once above the words.
/// Scrolls when a large text scale makes it taller than the room it has.
class CouponsEmptyView extends StatelessWidget {
  const CouponsEmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - AppSpacing.s24 * 2,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StateArt(asset: HeroAssets.emptyCoupons),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subheadingLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
