import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/checkout_bar_fact.dart';
import '../../../domain/entities/checkout_block_reason.dart';

/// One line under the place-order bar's total: a 14 dp icon and one line of
/// 14 sp text that ellipsizes instead of wrapping (large text, Arabic). A
/// reason the order cannot go reads in the error colours; "choose an
/// address" in grey; the savings and delivery facts in ink.
class CheckoutBarFactText extends StatelessWidget {
  const CheckoutBarFactText({super.key, required this.fact});

  static const double iconSize = AppSize.s14;

  final CheckoutBarFact fact;

  /// What a blocking [reason] says — the pinned line under the total and the
  /// snack a tap on the disabled button shows. [shortfallKd] fills the
  /// minimum-order reason; [pickup] picks the branch wording for a missing
  /// destination. The cart's reasons use the cart's own words.
  static String reasonText(
    CheckoutBlockReason reason, {
    double shortfallKd = 0,
    bool pickup = false,
  }) => switch (reason) {
    CheckoutBlockReason.maintenance => 'checkout.blocked_maintenance'.tr(),
    CheckoutBlockReason.destination =>
      pickup
          ? 'checkout.blocked_branch'.tr()
          : 'checkout.blocked_destination'.tr(),
    CheckoutBlockReason.slot => 'checkout.blocked_slot'.tr(),
    CheckoutBlockReason.notesTooLong => 'checkout.blocked_notes'.tr(),
    CheckoutBlockReason.offline => 'cart.block_offline'.tr(),
    CheckoutBlockReason.empty => 'checkout.cart_empty'.tr(),
    CheckoutBlockReason.lineIssue => 'cart.block_line_issue'.tr(),
    CheckoutBlockReason.minOrder => 'cart.block_min_order'.tr(
      namedArgs: {'amount': Formatters.price(shortfallKd)},
    ),
    CheckoutBlockReason.branchClosed => 'cart.block_branch_closed'.tr(),
    CheckoutBlockReason.capacity => 'cart.block_no_capacity'.tr(),
    CheckoutBlockReason.payment => 'checkout.blocked_payment'.tr(),
  };

  /// The words of [fact] (also what the bar reads out for all its facts).
  static String textOf(CheckoutBarFact fact) {
    final amount = Formatters.price(fact.kd);
    return switch (fact.kind) {
      // `CheckoutBarFact.blocked` is the only way to build this kind, and
      // it takes the reason: there is no fallback wording to fall into.
      CheckoutBarFactKind.blocked => reasonText(
        fact.reason!,
        shortfallKd: fact.kd,
      ),
      CheckoutBarFactKind.chooseDestination =>
        'checkout.bar_choose_destination'.tr(),
      CheckoutBarFactKind.totalSavings => 'checkout.bar_savings'.tr(
        namedArgs: {'amount': amount},
      ),
      CheckoutBarFactKind.couponSaved => 'checkout.bar_coupon'.tr(
        namedArgs: {'amount': amount, 'code': fact.code},
      ),
      CheckoutBarFactKind.pointsSaved => 'checkout.bar_points'.tr(
        namedArgs: {'amount': amount},
      ),
      CheckoutBarFactKind.freeDelivery => 'core.free_delivery'.tr(),
      CheckoutBarFactKind.freeDeliveryGap => 'checkout.bar_free_gap'.tr(
        namedArgs: {'amount': amount},
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, textColor) = switch (fact.kind) {
      CheckoutBarFactKind.blocked => (
        Icons.info_outline_rounded,
        AppColors.error,
        AppColors.errorDeep,
      ),
      CheckoutBarFactKind.chooseDestination => (
        Icons.location_on_outlined,
        AppColors.secondaryText,
        AppColors.secondaryText,
      ),
      CheckoutBarFactKind.totalSavings => (
        Icons.discount_rounded,
        AppColors.accent1,
        AppColors.primaryText,
      ),
      CheckoutBarFactKind.couponSaved => (
        Icons.confirmation_number_rounded,
        AppColors.accent1Dark,
        AppColors.primaryText,
      ),
      CheckoutBarFactKind.pointsSaved => (
        Icons.stars_rounded,
        AppColors.proAmber,
        AppColors.primaryText,
      ),
      CheckoutBarFactKind.freeDelivery => (
        Icons.delivery_dining_rounded,
        AppColors.freeDelivery,
        AppColors.primaryText,
      ),
      CheckoutBarFactKind.freeDeliveryGap => (
        Icons.delivery_dining_outlined,
        AppColors.secondaryText,
        AppColors.secondaryText,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(width: AppSpacing.s4),
        Flexible(
          child: Text(
            textOf(fact),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
