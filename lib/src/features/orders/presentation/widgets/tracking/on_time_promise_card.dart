import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import 'tracking_card.dart';

// ── On-time delivery promise ──────────────────────────────────────────────────
//
// Real Jameia surfaces an "on-time delivery promise" entry on the order-status
// page (`onTimePromiseHalfModalBg`, `ontime_promise_logo`, `ontime_promise_arrow`
// asset family). The live app shows it as a half-modal; the static clone renders
// it as a white promise card/row carrying the promise logo + copy + arrow.

class OnTimePromiseCard extends StatelessWidget {
  const OnTimePromiseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackingCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showOnTimePromiseSheet(context),
        borderRadius: BorderRadius.circular(AppRadius.r3),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s16,
          ),
          child: Row(
            children: [
              // Promise logo PNG (ontime_promise_logo_544iy5.png).
              Image.asset(
                JameiaAssets.onTimePromiseLogo,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  JameiaIcons.deliveryTime,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'orders.ontime_promise'.tr(),
                      style: AppTextStyles.subheadingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'orders.ontime_promise_sub'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              // Promise arrow chevron (ontime_promise_arrow_viht0r.png) — fall
              // back to the standard right-arrow glyph if the asset is missing.
              const Icon(
                JameiaIcons.arrowRight,
                size: 16,
                color: AppColors.tertiaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showOnTimePromiseSheet(BuildContext context) {
  showJameiaBottomSheet<void>(
    context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (sheetCtx) {
      final bottomPad = MediaQuery.paddingOf(sheetCtx).bottom;
      return Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.s20,
          end: AppSpacing.s20,
          top: AppSpacing.s16,
          bottom: bottomPad + AppSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              JameiaAssets.onTimePromiseLogo,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                JameiaIcons.deliveryTime,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'orders.ontime_guarantee'.tr(),
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'orders.ontime_guarantee_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            AppButton(
              label: 'orders.got_it'.tr(),
              radius: AppRadius.pill,
              onPressed: () => Navigator.maybePop(sheetCtx),
            ),
          ],
        ),
      );
    },
  );
}
