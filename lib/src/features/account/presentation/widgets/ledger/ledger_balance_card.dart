import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// Warm amber → orange points card at the top of the loyalty history (the
/// Rewards family): muted label, big value, an optional caption and the
/// [icon] in a white disc, over a soft ring in the corner. Static — the
/// points never count up on open.
class LedgerBalanceCard extends StatelessWidget {
  const LedgerBalanceCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption = '',
  });

  static const List<Color> _gradient = [
    AppColors.proAmber,
    AppColors.accent3,
    kJameiaPillPin,
  ];
  static const double _shadowAlpha = 0.22;
  static final List<BoxShadow> _shadow = [
    BoxShadow(
      color: kJameiaPillPin.withValues(alpha: _shadowAlpha),
      offset: const Offset(0, AppSpacing.s8),
      blurRadius: AppSize.s24,
      spreadRadius: -AppSpacing.s6,
    ),
  ];
  static const double _mutedAlpha = 0.88;
  static final Color _muted = AppColors.white.withValues(alpha: _mutedAlpha);
  static const double _ringAlpha = 0.14;
  static final Color _ring = AppColors.white.withValues(alpha: _ringAlpha);
  static const double _ringOverhang = -AppSpacing.s48;
  static const double _ringWidth = AppSpacing.s24;
  static const double _disc = AppSize.s48;

  final IconData icon;
  final String label;
  final String value;

  /// A secondary line (what the points are worth); hidden when empty.
  final String caption;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r2);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: _shadow,
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: _gradient,
          ),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              PositionedDirectional(
                top: _ringOverhang,
                end: _ringOverhang,
                child: SizedBox.square(
                  dimension: AppSize.s180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _ring, width: _ringWidth),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppTextStyles.subheadingMedium.copyWith(
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            value,
                            style: AppTextStyles.displayLarge.copyWith(
                              fontSize: AppSize.font40,
                              height: AppSize.lh1_2,
                              fontWeight: AppTextStyles.bold,
                              color: AppColors.white,
                            ),
                          ),
                          if (caption.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s2),
                            Text(
                              caption,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: AppTextStyles.medium,
                                color: _muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    ExcludeSemantics(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: _disc,
                          child: Icon(
                            icon,
                            size: AppSize.s32,
                            color: AppColors.accent3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
