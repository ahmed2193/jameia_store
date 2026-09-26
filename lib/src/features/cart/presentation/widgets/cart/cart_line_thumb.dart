import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/jameia_card_image.dart';

/// A cart row's 56 dp picture with 12 dp corners and a hairline drawn over
/// it (white packshots on the white page). The image clips itself and
/// decodes at its box size.
class CartLineThumb extends StatelessWidget {
  const CartLineThumb({super.key, required this.url});

  static const BoxDecoration _hairline = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
  );

  final String url;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: _hairline,
      child: JameiaCardImage(
        url: url,
        width: AppSize.s56,
        height: AppSize.s56,
        radius: AppRadius.card,
      ),
    );
  }
}
