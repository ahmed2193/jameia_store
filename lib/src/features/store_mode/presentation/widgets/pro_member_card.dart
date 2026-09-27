import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/light_sweep.dart';
import '../../domain/entities/pro_membership.dart';

/// A member's Pro card: the Pro gradient with a crown, "Hero Pro", the
/// plan, when it renews (or until when its benefits run after a
/// cancellation), a hint and the card "number" — a slow holographic sheen
/// sweeps across it now and then.
class ProMemberCard extends StatelessWidget {
  const ProMemberCard({super.key, required this.subscription});

  static const double _crown = AppSize.s32;
  static const double _bigRing = AppSize.s160;
  static const double _smallRing = AppSize.s100;
  static const double _ringOverhang = AppSize.s48;
  static const double _ringAlpha = 0.1;
  static const double _hintAlpha = 0.85;
  static const double _numberSpacing = AppSize.s2;

  static const LinearGradient _gradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: AppColors.proGradient,
  );

  final ProSubscription subscription;

  @override
  Widget build(BuildContext context) {
    final date = Formatters.date(
      context.locale.languageCode,
      subscription.currentPeriodEnd,
    );
    final statusKey = subscription.cancelAtPeriodEnd
        ? 'pro.benefits_until'
        : 'pro.renews_on';
    final ring = BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.white.withValues(alpha: _ringAlpha),
    );
    final hint = AppColors.white.withValues(alpha: _hintAlpha);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(AppRadius.r2),
        boxShadow: AppShadows.high,
      ),
      child: LightSweep(
        child: Stack(
          children: [
            PositionedDirectional(
              end: -_ringOverhang,
              top: -_ringOverhang,
              child: SizedBox.square(
                dimension: _bigRing,
                child: DecoratedBox(decoration: ring),
              ),
            ),
            PositionedDirectional(
              start: -_ringOverhang,
              bottom: -_ringOverhang,
              child: SizedBox.square(
                dimension: _smallRing,
                child: DecoratedBox(decoration: ring),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: _crown,
                        color: AppColors.proAmber,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          'pro.title'.tr(),
                          style: AppTextStyles.headingLarge.copyWith(
                            fontWeight: AppTextStyles.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s8,
                          vertical: AppSpacing.s2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: hint),
                        ),
                        child: Text(
                          subscription.planName,
                          maxLines: 1,
                          style: AppTextStyles.subheadingSmall.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  if (date.isNotEmpty)
                    Text(
                      statusKey.tr(namedArgs: {'date': date}),
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.white,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'pro.member_card_hint'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(color: hint),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  ExcludeSemantics(
                    child: Text(
                      'pro.member_card_number'.tr(),
                      style: AppTextStyles.subheadingMedium.copyWith(
                        color: hint,
                        letterSpacing: _numberSpacing,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
