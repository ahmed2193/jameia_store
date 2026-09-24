import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';

/// A rounded white card on the cart's grey page. A [Material], so a tappable
/// row inside it (coupon, loyalty) paints its ink on the card itself — over a
/// plain coloured box the splash would land on the Scaffold, behind the white.
class CartSectionCard extends StatelessWidget {
  const CartSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s12,
        AppSpacing.s12,
        AppSpacing.s12,
        0,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSize.r16),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
