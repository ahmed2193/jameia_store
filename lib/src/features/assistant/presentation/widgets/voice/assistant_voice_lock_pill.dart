import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/float_loop.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/responsive/app_size.dart';
import 'assistant_voice_drag.dart';

/// The lock above the held mic (WhatsApp): an open padlock and a chevron
/// that nudges up ONCE as the pill appears say "slide up" (docs/motion §9.6
/// §2.9 — it never bobs on). As the finger climbs, the pill shortens; at the
/// top the padlock snaps shut ([PopSwitcher], `snappy`) and the recording
/// locks. Heading for the bin instead, it fades away.
///
/// The pill shortens inside a box of fixed size, toward its foot, in a
/// layer of its own: a move lays out and repaints the pill alone, not the
/// page around it.
class AssistantVoiceLockPill extends StatelessWidget {
  const AssistantVoiceLockPill({super.key, required this.drag});

  final ValueListenable<AssistantVoiceDrag> drag;

  static const double width = AppSize.s40;
  static const double _tallest = AppSize.s96;
  static const double _shortest = AppSize.s56;

  /// The padlock turns brand-coloured past this share of the climb.
  static const double _closing = 0.6;

  /// How far the pill rises as it appears.
  static const double _rise = AppSize.s24;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _tallest,
      child: RepaintBoundary(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: AppMotion.emphasizedDecelerate,
            builder: (context, shown, child) => Opacity(
              opacity: shown,
              child: Transform.translate(
                offset: Offset(0, (1 - shown) * _rise),
                child: child,
              ),
            ),
            child: ValueListenableBuilder<AssistantVoiceDrag>(
              valueListenable: drag,
              builder: (context, value, _) {
                final climb = value.lockProgress;
                return Opacity(
                  opacity: 1 - value.cancelProgress,
                  child: Container(
                    width: width,
                    height: lerpDouble(_tallest, _shortest, climb),
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: AppSpacing.s8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PopSwitcher(
                          stateKey: climb >= 1,
                          child: Icon(
                            climb >= 1
                                ? Icons.lock_rounded
                                : Icons.lock_open_rounded,
                            size: AppSize.s20,
                            color: climb >= _closing
                                ? AppColors.primaryDark
                                : AppColors.secondaryText,
                          ),
                        ),
                        Opacity(
                          opacity: 1 - climb,
                          child: const FloatLoop(
                            amplitude: AppSize.s3,
                            count: 1,
                            child: Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: AppSize.s20,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
