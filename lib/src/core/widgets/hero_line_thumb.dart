import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';
import 'hero_card_image.dart';

/// A basket line's picture: [size] square (56 dp, the cart row's size, so
/// the cart, the checkout strip, its items sheet and the savings hint share
/// one CDN url and one decode), 12 dp corners and a hairline drawn over it
/// (white packshots on a white page). The image clips itself and decodes at
/// its box size.
class HeroLineThumb extends StatelessWidget {
  const HeroLineThumb({super.key, required this.url, this.size = AppSize.s56});

  static const BoxDecoration _hairline = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.divider)),
  );

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: _hairline,
      child: HeroCardImage(
        url: url,
        width: size,
        height: size,
        radius: AppRadius.card,
      ),
    );
  }
}
