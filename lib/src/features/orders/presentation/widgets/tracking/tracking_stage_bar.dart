import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/ambient_loop.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/order_journey.dart';
import 'tracking_stage_bar_painter.dart';

/// The journey as four segments (received → packing → on the way →
/// delivered), the way delivery apps draw it: the stages behind are full,
/// the stage in progress fills out and back a few times and rests as a
/// short stub, the stages ahead are grey.
///
/// Motion: the bar opens already drawn at the order's stage — no sweep on
/// every visit. A live change (a poll moved the order) fills on from the old
/// stage in one [_fillDuration] sweep; the in-progress run is an [AmbientLoop]
/// (on screen, foreground, not reduced, capped by the ambient budget),
/// re-armed for each new stage. Reduced motion: drawn at the final state,
/// nothing runs. Read out as "Packing. Step 2 of 4".
class TrackingStageBar extends StatefulWidget {
  const TrackingStageBar({super.key, required this.journey});

  final OrderJourney journey;

  @override
  State<TrackingStageBar> createState() => _TrackingStageBarState();
}

class _TrackingStageBarState extends State<TrackingStageBar>
    with SingleTickerProviderStateMixin {
  /// One stage's fill: long enough to read as progress, not a snap.
  static const Duration _fillDuration = AppMotion.drawOn;

  /// One out-and-back of the in-progress run (a progress cue: the loader's
  /// cadence), then its rest.
  static const Duration _runLap = AppMotion.loaderOrbit;
  static const Duration _runRest = AppMotion.slow;

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: _fillDuration,
    upperBound: OrderJourney.stageCount.toDouble(),
    value: widget.journey.filledSegments.toDouble(),
  );

  @override
  void didUpdateWidget(TrackingStageBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.journey.filledSegments.toDouble();
    if (target == _fill.value && !_fill.isAnimating) return;
    if (MotionGuard.reduced(context)) {
      _fill.value = target;
      return;
    }
    // An explicit duration: the controller spans four stages, and without
    // one a one-stage step would run a quarter of it.
    _fill.animateTo(
      target,
      duration: _fillDuration,
      curve: AppMotion.emphasizedDecelerate,
    );
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.journey.tone) {
    OrderJourneyTone.attention => AppColors.warn,
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final step = (journey.stageIndex ?? 0) + 1;
    return Semantics(
      label:
          '${journey.stageLabelKey.tr()}. '
          '${'orders.progress_step'.tr(namedArgs: {'step': '$step', 'total': '${OrderJourney.stageCount}'})}',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            height: AppSize.s6,
            width: double.infinity,
            // A new stage gets a new loop: its run plays again from the top.
            child: AmbientLoop(
              key: ValueKey<int?>(journey.stageIndex),
              period: _runLap,
              rest: _runRest,
              reverse: true,
              curve: AppMotion.machEaseInOut,
              active: journey.inProgress,
              builder: (context, loop, _) => CustomPaint(
                painter: TrackingStageBarPainter(
                  fill: _fill,
                  sweep: loop,
                  segments: OrderJourney.stageCount,
                  current: journey.stageIndex,
                  inProgress: journey.inProgress,
                  gap: AppSpacing.s4,
                  fillColor: _color,
                  textDirection: Directionality.of(context),
                  repaint: Listenable.merge([_fill, loop]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
