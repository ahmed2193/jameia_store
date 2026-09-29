import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';
import '../utils/formatters.dart';
import 'cart_bar_summary.dart';

/// The "View cart" card of a catalogue page's bottom bar: a white rounded
/// card on a soft shadow with the green basket and its count (which pops
/// when the count changes), the basket's subtotal rolling to its new value,
/// the delivery line under it ("Free delivery" / "KD 0.650 delivery", from
/// [deliveryKd]), and "View cart" at the end. The basket can be the target
/// items fly into ([targetKey]). Reads as one button.
class ViewCartPill extends StatelessWidget {
  const ViewCartPill({
    super.key,
    required this.count,
    required this.totalKd,
    required this.onTap,
    this.deliveryKd,
    this.targetKey,
  });

  final int count;
  final double totalKd;
  final VoidCallback onTap;

  /// `0` = free delivery, more = the fee, `null` = no delivery line
  /// (`CartEntity.deliveryQuoteKd`).
  final double? deliveryKd;

  /// Put on the basket, for `FlyToCart.pushTarget`.
  final GlobalKey? targetKey;

  /// The card's least height (a larger text scale grows it).
  static const double height = AppSize.s72;

  @override
  Widget build(BuildContext context) {
    final label = 'core.view_cart'.tr();
    final total = Formatters.price(totalKd);
    return Semantics(
      button: true,
      label: '$label, $count, $total',
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: height),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s12,
            AppSpacing.s10,
            AppSpacing.s20,
            AppSpacing.s10,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.r2),
            boxShadow: AppShadows.high,
          ),
          child: Row(
            children: [
              Expanded(
                child: CartBarSummary(
                  count: count,
                  amountKd: totalKd,
                  deliveryKd: deliveryKd,
                  targetKey: targetKey,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(
                label,
                maxLines: 1,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
