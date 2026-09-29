import 'package:flutter/material.dart';

import '../../../../../../config/theme/app_colors.dart';
import '../../../../../../config/theme/app_shadows.dart';
import '../../../../../../core/responsive/app_size.dart';
import '../../../../../../core/widgets/count_badge.dart';

/// The cart demo's cart: a white disc that pops in with [appear] and
/// carries the app's own count pill ([CountBadge], like the chat's cart
/// button): the count waits for the thumbnail flying in to land, then bumps
/// and rolls. [cartKey] marks the disc as where the flights land.
class AssistantOnboardingCartBadge extends StatelessWidget {
  const AssistantOnboardingCartBadge({
    super.key,
    required this.cartKey,
    required this.count,
    required this.appear,
  });

  final GlobalKey cartKey;
  final int count;
  final double appear;

  static const double _disc = AppSize.s44;
  static const double _countOut = -AppSize.s2;
  static const BoxDecoration _face = BoxDecoration(
    color: AppColors.white,
    shape: BoxShape.circle,
    boxShadow: AppShadows.low,
  );

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: appear,
      child: SizedBox.square(
        dimension: _disc,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                key: cartKey,
                decoration: _face,
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  size: AppSize.s22,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            PositionedDirectional(
              top: _countOut,
              end: _countOut,
              child: CountBadge(
                count: count,
                color: AppColors.accent1,
                minSize: AppSize.s20,
                landsWithFlight: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
