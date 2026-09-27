import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'checkout_coupons_row.dart';
import 'checkout_points_row.dart';
import 'checkout_unlock_tag.dart';

/// The Hero voucher card: cream, a faint tan hairline, 12 dp corners, the
/// coupons-and-offers row and (when it applies) the points row under a
/// hairline. The red unlock tag sits on the card's top edge at the end, half
/// outside it, so however long it gets it never covers the row's text; it
/// lets taps through to the row.
class CheckoutSavingsCard extends StatelessWidget {
  const CheckoutSavingsCard({super.key});

  /// How far the tag rises above the card's top edge (half its height).
  static const double _tagLift = AppSize.s8;

  static const ShapeBorder _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
    side: BorderSide(color: AppColors.voucherTanFaint, width: AppSize.s1),
  );

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.voucherCream,
          shape: _shape,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [CheckoutCouponsRow(), CheckoutPointsRow()],
          ),
        ),
        PositionedDirectional(
          top: -_tagLift,
          start: AppSpacing.s12,
          end: AppSpacing.s8,
          child: IgnorePointer(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: CheckoutUnlockTag(),
            ),
          ),
        ),
      ],
    );
  }
}
