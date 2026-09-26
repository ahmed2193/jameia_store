import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import 'reward_applying_overlay.dart';
import 'reward_card_backdrop.dart';
import 'reward_card_face.dart';
import 'reward_off_pill.dart';

/// The "image" of a reward card: the warm backdrop (its gift gently floating
/// on ready cards when [floats]), the points and the discount pill, which
/// pops in right after the card's own entrance starts. Locked tiers sit
/// behind a light veil with a lock; the tier being redeemed fades in the
/// applying overlay; the tier on the basket gets a green ring. Ready cards
/// cast a soft warm shadow.
class RewardCardArt extends StatelessWidget {
  const RewardCardArt({
    super.key,
    required this.points,
    required this.offLabel,
    required this.isLocked,
    required this.isApplying,
    required this.isApplied,
    required this.floats,
    required this.popDelay,
  });

  final int points;

  /// "KD 0.100 off".
  final String offLabel;
  final bool isLocked;
  final bool isApplying;
  final bool isApplied;

  /// The gift idles up and down (the screen caps how many cards loop).
  final bool floats;

  /// When the card's own entrance starts; the pill pops right after it.
  final Duration popDelay;

  static const double _aspectRatio = 1.17;
  static const double _lockedVeilAlpha = 0.5;
  static final Color _lockedVeil = AppColors.white.withValues(
    alpha: _lockedVeilAlpha,
  );
  static const double _shadowAlpha = 0.28;
  static const Offset _shadowOffset = Offset(0, AppSpacing.s6);
  static final List<BoxShadow> _readyShadow = [
    BoxShadow(
      color: kJameiaPillPin.withValues(alpha: _shadowAlpha),
      offset: _shadowOffset,
      blurRadius: AppSize.s14,
      spreadRadius: -AppSpacing.s4,
    ),
  ];
  static const double _ringWidth = AppSize.s2_5;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r3);
    final lead = popDelay + AppMotion.fast;
    final popDuration = lead + AppMotion.medium;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: isApplied
            ? Border.all(color: AppColors.success, width: _ringWidth)
            : null,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: isLocked ? null : _readyShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RewardCardBackdrop(floats: floats && !isLocked),
                if (isLocked) ColoredBox(color: _lockedVeil),
                RewardCardFace(points: points, isLocked: isLocked),
                PositionedDirectional(
                  top: AppSpacing.s10,
                  start: AppSpacing.s10,
                  end: AppSpacing.s10,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: PopScale.onMount(
                      duration: popDuration,
                      curve: Interval(
                        lead.inMicroseconds / popDuration.inMicroseconds,
                        1,
                        curve: AppMotion.emphasized,
                      ),
                      child: RewardOffPill(label: offLabel),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: MotionGuard.duration(context, AppMotion.medium),
                    child: isApplying
                        ? const RewardApplyingOverlay()
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
