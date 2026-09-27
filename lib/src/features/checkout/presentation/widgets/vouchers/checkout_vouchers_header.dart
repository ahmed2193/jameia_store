import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// A section head of the "Coupons & offers" page ("Your coupon", "Applied
/// to your order", "Add more to unlock"): 18 sp bold, 12 dp in from the
/// screen edge (the cards sit on the 9 dp page margin), 24 dp above and
/// 16 dp below.
class CheckoutVouchersHeader extends StatelessWidget {
  const CheckoutVouchersHeader({super.key, required this.title});

  final String title;

  /// The page margin is 9 dp; the heads start at 12.
  static const double _inset = AppSpacing.s12 - AppSpacing.pageMargin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        _inset,
        AppSpacing.s24,
        _inset,
        AppSpacing.s16,
      ),
      child: Semantics(
        header: true,
        child: Text(title, style: AppTextStyles.groupTitle),
      ),
    );
  }
}
