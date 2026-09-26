import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/skeleton_bone.dart';
import '../../../../../core/widgets/skeletonized.dart';
import 'ledger_entry_tile.dart';

/// First load of a wallet / points screen: the balance card, the history
/// title and real history rows as shimmering bones (a still bone under
/// reduced motion), so the content lands where the skeleton was.
class LedgerSkeleton extends StatelessWidget {
  const LedgerSkeleton({super.key});

  static const int _rows = 6;
  static const int _amountChars = 7;
  static const double _cardHeight = AppSize.s180;
  static const double _titleWidth = AppSize.s140;
  static const double _dayWidth = AppSize.s64;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      child: Skeletonized(
        loading: true,
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.s16),
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s16,
              ),
              child: SkeletonBone(height: _cardHeight, radius: AppRadius.r2),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                AppSpacing.s24,
                AppSpacing.s16,
                AppSpacing.s8,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SkeletonBone(width: _titleWidth, height: AppSize.s22),
              ),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                AppSpacing.s14,
                AppSpacing.s16,
                AppSpacing.s6,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SkeletonBone(width: _dayWidth, height: AppSize.s14),
              ),
            ),
            for (var row = 0; row < _rows; row++)
              LedgerEntryTile(
                icon: Icons.receipt_long_outlined,
                title: BoneMock.title,
                time: BoneMock.date,
                amount: BoneMock.chars(_amountChars),
                isCredit: false,
              ),
          ],
        ),
      ),
    );
  }
}
