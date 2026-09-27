import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';
import 'jameia_mark_icon_painter.dart';

/// The app icon's cart mark used as an icon. Like an [Icon], it takes its
/// size and colour from the surrounding [IconTheme]. When [active] it grows
/// into the app icon itself (white cart, yellow slats, green tile), and the
/// cart hops once on the way, like on the splash.
class JameiaMarkIcon extends StatelessWidget {
  const JameiaMarkIcon({super.key, this.active = false, this.size});

  final bool active;

  /// Side in dp; the [IconTheme]'s size when `null`.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? AppSize.s24;
    final ink = theme.color ?? AppColors.primaryText;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: active ? 1 : 0),
      duration: MotionGuard.duration(context, AppMotion.popup),
      curve: MotionGuard.curve(context, AppMotion.signature),
      builder: (_, progress, _) => CustomPaint(
        size: Size.square(side),
        painter: JameiaMarkIconPainter(
          progress: progress,
          ink: ink,
          hop: active,
        ),
      ),
    );
  }
}
