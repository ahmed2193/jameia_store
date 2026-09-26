import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import 'cart_deal_node.dart';

/// The deals strip's track: a start milestone (ticked once any offer is
/// earned), the line filling towards the next offer, and the end milestone
/// (ticked once every offer is earned). The fill glides to its new value
/// when the cart changes, in its own repaint layer.
class CartDealTrack extends StatelessWidget {
  const CartDealTrack({
    super.key,
    required this.fraction,
    required this.startReached,
    required this.endReached,
  });

  /// 0..1 towards the next offer.
  final double fraction;
  final bool startReached;
  final bool endReached;

  static const BorderRadius _radius = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          CartDealNode(reached: startReached),
          Expanded(
            child: RepaintBoundary(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: endReached ? 1 : fraction),
                duration: MotionGuard.duration(context, AppMotion.slow),
                curve: AppMotion.emphasizedDecelerate,
                builder: (_, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: AppSize.s5,
                  borderRadius: _radius,
                  backgroundColor: AppColors.white,
                  color: AppColors.brandDeep,
                ),
              ),
            ),
          ),
          CartDealNode(reached: endReached),
        ],
      ),
    );
  }
}
