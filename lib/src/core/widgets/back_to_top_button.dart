import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../motion/motion.dart';
import '../motion/motion_widgets.dart';
import '../responsive/app_size.dart';

/// The round "back to the top" button: it pops up (scale + fade) while
/// [shown] and shrinks away otherwise. Hidden, it takes no taps and reads to
/// nobody. Placed and driven by [BackToTopOverlay].
class BackToTopButton extends StatelessWidget {
  const BackToTopButton({super.key, required this.shown, required this.onTap});

  final bool shown;
  final VoidCallback onTap;

  static const double size = AppSize.s44;
  static const double _hiddenScale = 0.6;
  static const double _glyph = AppSize.s26;

  @override
  Widget build(BuildContext context) {
    final duration = MotionGuard.duration(context, AppMotion.medium);
    return IgnorePointer(
      ignoring: !shown,
      child: ExcludeSemantics(
        excluding: !shown,
        child: AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: duration,
          child: AnimatedScale(
            scale: shown ? 1 : _hiddenScale,
            duration: duration,
            curve: shown ? AppMotion.emphasized : AppMotion.exit,
            child: Semantics(
              button: true,
              label: 'core.back_to_top'.tr(),
              // Replaces the child's semantics, its tap action included.
              excludeSemantics: true,
              onTap: onTap,
              child: PressScale(
                onTap: onTap,
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.medium,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: _glyph,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
