import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../../../core/responsive/app_size.dart';

/// Unread-count pill next to a menu label: 20dp tall, bold 12dp, "99+"
/// above 99 (laid out left-to-right, so Arabic does not show "+99"). It
/// appears as is and gives one springy pop only when the count CHANGES
/// while on screen — never on mount or on a tab visit. Reduced motion → no
/// pop.
class MineUnreadBadge extends StatefulWidget {
  const MineUnreadBadge({super.key, required this.count});

  final int count;

  @override
  State<MineUnreadBadge> createState() => _MineUnreadBadgeState();
}

class _MineUnreadBadgeState extends State<MineUnreadBadge>
    with SingleTickerProviderStateMixin {
  static const int _maxShown = 99;
  static const double _popFrom = 0.85;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppSprings.snappy.duration,
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: _popFrom,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: AppSprings.snappy));

  @override
  void didUpdateWidget(MineUnreadBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count == widget.count) return;
    if (MotionGuard.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    final text = count > _maxShown ? '$_maxShown+' : '$count';
    return ScaleTransition(
      scale: _scale,
      child: Container(
        height: AppSize.s20,
        constraints: const BoxConstraints(minWidth: AppSize.s20),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.unreadBadgeBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text,
            maxLines: 1,
            style: AppTextStyles.captionLarge.copyWith(
              fontWeight: AppTextStyles.bold,
              color: AppColors.skuOptionFg,
              height: AppSize.s1,
            ),
          ),
        ),
      ),
    );
  }
}
