import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/widgets/shelf_pro_price_chip.dart';
import '../../../../core/widgets/shelf_save_badge.dart';
import '../../domain/entities/product_price_quote.dart';
import 'pdp_bar_price.dart';
import 'pdp_info_chip.dart';

/// The buy bar's price block, Hero style, top to bottom: the lime
/// "Save N%" of a deal (popping in again for another percent), the bold
/// price with its marker and struck total ([PdpBarPrice]), then the Pro line
/// — what a member would pay, for a customer who is not one, or "Pro price"
/// for a member who pays it. It eases to its new height as lines come and go
/// (another option) and shrinks to fit a narrow bar. Everything it shows is
/// the domain's [quote].
class PdpBarPriceBlock extends StatelessWidget {
  const PdpBarPriceBlock({super.key, required this.quote, this.option});

  final ProductPriceQuote quote;

  /// What is priced (the chosen option): see [PdpBarPrice.option].
  final Object? option;

  @override
  Widget build(BuildContext context) {
    final hint = quote.proHintKd;
    final save = quote.savePercent;
    return AnimatedSize(
      duration: MotionGuard.duration(context, AppMotion.fast),
      curve: AppMotion.signature,
      alignment: AlignmentDirectional.bottomStart,
      // Loose, so the fit keeps the block's own height (a tight width would
      // make it keep its aspect ratio instead).
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        heightFactor: 1,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (save > 0) ...[
                PopScale(
                  popKey: save,
                  child: ShelfSaveBadge(percent: save),
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
              PdpBarPrice(
                amountKd: quote.amountKd,
                struckKd: quote.struckKd,
                deal: quote.isDeal,
                option: option,
              ),
              if (hint != null) ...[
                const SizedBox(height: AppSpacing.s4),
                ShelfProPriceChip(priceKd: hint),
              ] else if (quote.proApplied) ...[
                const SizedBox(height: AppSpacing.s4),
                PdpInfoChip(
                  label: 'product.pro_price_applied'.tr(),
                  foreground: AppColors.accentViolet,
                  background: AppColors.accentVioletLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
