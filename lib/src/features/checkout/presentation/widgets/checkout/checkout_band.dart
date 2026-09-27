import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';

/// One block of the checkout page: a 10 dp grey band above it (unless
/// [bandAbove] is off), then the block on white — or on [gradient] (the
/// rail's mint wash) — with [padding] around [child] (20 dp below by
/// default, the block's bottom rhythm).
///
/// The block is its own transparent [Material], so the ink of the rows in
/// it (flat list rows, choice rows) shows above the white fill instead of
/// on the page's surface underneath.
class CheckoutBand extends StatelessWidget {
  const CheckoutBand({
    super.key,
    required this.child,
    this.bandAbove = true,
    this.gradient,
    this.padding = const EdgeInsetsDirectional.only(bottom: AppSpacing.s20),
  });

  final Widget child;
  final bool bandAbove;

  /// Replaces the white fill.
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final block = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.white : null,
        gradient: gradient,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (!bandAbove) return block;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: AppSpacing.s10,
          child: ColoredBox(color: AppColors.smallBackground),
        ),
        block,
      ],
    );
  }
}
