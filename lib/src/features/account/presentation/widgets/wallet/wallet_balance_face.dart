import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import 'wallet_balance_amount.dart';
import 'wallet_delta_chip.dart';

/// The wallet card itself: a deep brand-green gradient with a soft ring in
/// the corner, the label (and, for a moment after a refresh, the delta
/// chip) next to the wallet disc, the balance, and how the balance is used.
/// Pure layout — the timing lives in `WalletBalanceCard`.
class WalletBalanceFace extends StatelessWidget {
  const WalletBalanceFace({
    super.key,
    required this.balanceFils,
    required this.deltaFils,
    required this.chipOpacity,
    required this.chipRise,
  });

  /// Deep emerald where the text starts, brand green toward the far
  /// corner: the white text keeps its contrast, the card still reads green.
  static const List<double> _stops = [0, 0.55, 1];
  static final Gradient _fill = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [AppColors.green[11], AppColors.accent2Dark, AppColors.primaryDark],
    stops: _stops,
  );
  static const double _shadowAlpha = 0.28;
  static final List<BoxShadow> _shadow = [
    BoxShadow(
      color: AppColors.primaryDark.withValues(alpha: _shadowAlpha),
      offset: const Offset(0, AppSpacing.s8),
      blurRadius: AppSize.s24,
      spreadRadius: -AppSpacing.s6,
    ),
  ];
  static const double _mutedAlpha = 0.88;
  static final Color _muted = AppColors.white.withValues(alpha: _mutedAlpha);
  static const double _ringAlpha = 0.12;
  static final Color _ring = AppColors.white.withValues(alpha: _ringAlpha);
  static const double _ruleAlpha = 0.2;
  static final Color _rule = AppColors.white.withValues(alpha: _ruleAlpha);
  static const double _ringOverhang = -AppSpacing.s48;
  static const double _ringWidth = AppSpacing.s24;
  static const double _disc = AppSize.s44;

  final int balanceFils;

  /// The delta the chip shows; 0 = no chip.
  final int deltaFils;
  final Animation<double> chipOpacity;
  final Animation<double> chipRise;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r2);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _shadow,
        gradient: _fill,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'wallet.balance'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subheadingMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      if (deltaFils != 0) ...[
                        WalletDeltaChip(
                          deltaFils: deltaFils,
                          opacity: chipOpacity,
                          rise: chipRise,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                      ],
                      const ExcludeSemantics(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(
                            dimension: _disc,
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              size: AppSize.s24,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  WalletBalanceAmount(balanceFils: balanceFils),
                  const SizedBox(height: AppSpacing.s16),
                  Divider(
                    height: AppSize.s1,
                    thickness: AppSize.s1,
                    color: _rule,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: AppSize.s16,
                        color: _muted,
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: Text(
                          'wallet.balance_hint'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
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
