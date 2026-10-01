import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_app_logo.dart';

/// The store badge the home header opens with: the Hero app icon on a
/// rounded, hairline-framed tile.
class HomeStoreLogo extends StatelessWidget {
  const HomeStoreLogo({super.key});

  static const double size = AppSize.s48;

  static final BorderRadius _corners = BorderRadius.circular(_radius);
  static const double _radius = AppSize.r12;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // Over the artwork, so the frame is not hidden under it.
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: _corners,
        border: Border.all(color: AppColors.divider),
      ),
      child: const HeroAppLogo(size: size, radius: _radius),
    );
  }
}
