import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/rolling_number.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/wallet_entry_entity.dart';

/// The wallet balance in the card: the currency label, then the amount as a
/// money ticker ([RollingNumber] — static on open, only the changed digits
/// roll when the balance moves). Laid out left-to-right in every language
/// ("KD 12.750"; read right-to-left in Arabic it is "12.750 د.ك"); screen
/// readers hear the whole price once.
class WalletBalanceAmount extends StatelessWidget {
  const WalletBalanceAmount({super.key, required this.balanceFils});

  static const double _currencyAlpha = 0.88;
  static final Color _currencyInk = AppColors.white.withValues(
    alpha: _currencyAlpha,
  );

  final int balanceFils;

  static String _amount(num kd) => Formatters.amount(kd.toDouble());

  @override
  Widget build(BuildContext context) {
    final kd = WalletEntryEntity.kdOf(balanceFils);
    return Semantics(
      label: Formatters.price(kd),
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                Formatters.currency,
                style: AppTextStyles.headingLarge.copyWith(
                  fontSize: AppSize.font24,
                  fontWeight: AppTextStyles.bold,
                  color: _currencyInk,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              RollingNumber(
                value: kd,
                format: _amount,
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: AppSize.font40,
                  height: AppSize.lh1_2,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
