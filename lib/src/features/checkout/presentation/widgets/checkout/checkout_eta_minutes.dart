import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/flip_value.dart';
import '../../../domain/entities/checkout_eta.dart';

/// The value of the "Expected" row: the minutes (plural-correct), the booked
/// window ([slotText]), or why there is nothing to estimate — the closed
/// branch / missing capacity in the cart's own words, in a warning colour.
/// A new value flips in vertically; reduced motion swaps it at once.
class CheckoutEtaMinutes extends StatelessWidget {
  const CheckoutEtaMinutes({
    super.key,
    required this.eta,
    required this.isPickup,
    this.slotText,
  });

  final CheckoutEta eta;
  final bool isPickup;

  /// "Tomorrow · 10:00 – 12:00" for a booked window.
  final String? slotText;

  @override
  Widget build(BuildContext context) {
    final strong = AppTextStyles.label.copyWith(fontWeight: AppTextStyles.bold);
    final minutes = eta.minutes;
    final (text, style) = switch (eta.kind) {
      CheckoutEtaKind.unknown => (
        // Pickup: the branch row already asks for a branch.
        isPickup ? '' : 'checkout.eta_unknown'.tr(),
        AppTextStyles.label.copyWith(color: AppColors.secondaryText),
      ),
      CheckoutEtaKind.asap ||
      CheckoutEtaKind.express ||
      CheckoutEtaKind.pickup => (
        minutes == null ? '' : 'checkout.eta_minutes'.plural(minutes),
        strong,
      ),
      CheckoutEtaKind.scheduled => (slotText ?? '', strong),
      CheckoutEtaKind.branchClosed => (
        'cart.block_branch_closed'.tr(),
        AppTextStyles.label.copyWith(color: AppColors.errorDeep),
      ),
      CheckoutEtaKind.noCapacity => (
        'cart.block_no_capacity'.tr(),
        AppTextStyles.label.copyWith(color: AppColors.errorDeep),
      ),
    };
    return FlipValue(
      flipKey: text,
      child: Text(text, style: style),
    );
  }
}
