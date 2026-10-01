import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';

/// The round "Jump to latest" button over the chat. The list decides when
/// it shows ([visible]: the reader is away from the newest message — also
/// when the list moved itself to keep their place, which fires no scroll
/// event) and what a tap does. It fades in while settling from
/// [AppMotion.pressedScaleSmall] over `medium`; no haptic (navigation).
class AssistantJumpToLatest extends StatelessWidget {
  const AssistantJumpToLatest({
    super.key,
    required this.visible,
    required this.onTap,
  });

  final ValueListenable<bool> visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = 'assistant.jump_to_latest'.tr();
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, shown, child) {
        final duration = MotionGuard.duration(context, AppMotion.medium);
        return IgnorePointer(
          ignoring: !shown,
          child: ExcludeSemantics(
            excluding: !shown,
            // Fades while settling from 0.92 — never grown from nothing
            // (docs/motion §9.6 §2.12); its own layer.
            child: RepaintBoundary(
              child: AnimatedOpacity(
                opacity: shown ? 1 : 0,
                duration: duration,
                curve: AppMotion.signature,
                child: AnimatedScale(
                  scale: shown ? 1 : AppMotion.pressedScaleSmall,
                  duration: duration,
                  curve: AppMotion.signature,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Tooltip(
          message: label,
          child: Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.medium,
                ),
                child: SizedBox.square(
                  dimension: AppSize.s48,
                  child: HeroIcon(
                    HeroIcons.chevronDown,
                    size: AppSize.s28,
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
