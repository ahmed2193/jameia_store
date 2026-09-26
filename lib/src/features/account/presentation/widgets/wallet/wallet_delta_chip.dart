import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/wallet_entry_entity.dart';
import '../ledger/ledger_signed.dart';

/// "+KD 2.500" pill the balance card shows for a moment after a refresh
/// moved the balance: fades in while rising into place, holds, fades out
/// ([opacity] / [rise] come from the card's one timeline). A credit is a
/// white pill with green ink, a debit a neutral frosted one. Announced to
/// screen readers when it appears.
class WalletDeltaChip extends StatelessWidget {
  const WalletDeltaChip({
    super.key,
    required this.deltaFils,
    required this.opacity,
    required this.rise,
  });

  static const double _frostAlpha = 0.22;
  static final Color _frost = AppColors.white.withValues(alpha: _frostAlpha);

  final int deltaFils;
  final Animation<double> opacity;

  /// Vertical offset in logical pixels (down → 0).
  final Animation<double> rise;

  @override
  Widget build(BuildContext context) {
    final credit = deltaFils > 0;
    final ink = credit ? AppColors.primaryDark : AppColors.white;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return RepaintBoundary(
      child: FadeTransition(
        opacity: opacity,
        child: AnimatedBuilder(
          animation: rise,
          builder: (_, chip) =>
              Transform.translate(offset: Offset(0, rise.value), child: chip),
          child: Semantics(
            liveRegion: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: credit ? AppColors.white : _frost,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s8,
                  AppSpacing.s4,
                  AppSpacing.s10,
                  AppSpacing.s4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      credit
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: AppSize.s14,
                      color: ink,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      LedgerSigned.money(
                        WalletEntryEntity.kdOf(deltaFils),
                        rtl: rtl,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
