import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/sticker_text.dart';
import 'checkout_ticket_border.dart';

/// The ribbon in a ticket's top-end corner ("Combines with other offers",
/// "Can't be combined"): a red → orange wash from start to end, white
/// sticker letters, its top-end corner following the ticket's and a soft
/// bottom-start corner — so it needs no clip.
class CheckoutTicketRibbon extends StatelessWidget {
  const CheckoutTicketRibbon({super.key, required this.label});

  final String label;

  static const BoxDecoration _decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: AlignmentDirectional.centerStart,
      end: AlignmentDirectional.centerEnd,
      colors: [AppColors.couponBadgeRed, AppColors.accent1],
    ),
    borderRadius: BorderRadiusDirectional.only(
      topEnd: Radius.circular(CheckoutTicketBorder.radius),
      bottomStart: Radius.circular(AppRadius.r5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _decoration,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.s18),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s1,
          ),
          child: StickerText(
            label,
            rim: AppSize.s2,
            style: AppTextStyles.tag.copyWith(color: AppColors.white),
          ),
        ),
      ),
    );
  }
}
