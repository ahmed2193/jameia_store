import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/order_status.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import 'tracking_progress_painter.dart';

/// The journey as six pill segments (placed → confirmed → picking → ready →
/// out for delivery → delivered), filled up to the current [step].
///
/// Motion (the tracking page's hero): when the page opens (once the body has
/// faded in), the segments fill from the start edge up to the step in one
/// sweep, then the current segment breathes three times and rests — never on
/// the last step. A poll that moves the step fills on from the old step at
/// once. Nothing loops: the breath is a bounded `repeat(count:)`. Reduced
/// motion → painted at the final state, no controller runs. Read out as
/// "Step n of 6".
class TrackingProgressStepper extends StatefulWidget {
  const TrackingProgressStepper({super.key, required this.step});

  final int step;

  @override
  State<TrackingProgressStepper> createState() =>
      _TrackingProgressStepperState();
}

class _TrackingProgressStepperState extends State<TrackingProgressStepper>
    with TickerProviderStateMixin {
  /// Three breaths = six legs (in, out) of [AppMotion.breathe].
  static const int _breathLegs = 6;

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: AppMotion.countUp,
    upperBound: OrderStatus.progressSteps.toDouble(),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.breathe,
  );
  late final Listenable _repaint = Listenable.merge([_fill, _pulse]);
  bool _started = false;

  bool get _breathes => widget.step < OrderStatus.progressSteps - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _advance(entering: true);
  }

  @override
  void didUpdateWidget(TrackingProgressStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) _advance();
  }

  /// [entering]: the page's first sweep. The body is still fading in then
  /// (the page's fade-through holds it invisible for the first part of
  /// [AppMotion.page]), so the sweep waits one [AppMotion.page] — an
  /// [Interval] on the same controller, no timer — and is seen whole.
  void _advance({bool entering = false}) {
    _pulse.value = 0; // stops a breath in progress
    final target = widget.step + 1.0;
    if (MotionGuard.reduced(context)) {
      _fill.value = target;
      return;
    }
    final hold = entering ? AppMotion.page : Duration.zero;
    final total = hold + AppMotion.countUp;
    // `then` runs only when the sweep completes — a newer step (which stops
    // this one) or disposal never starts a stale breath.
    _fill
        .animateTo(
          target,
          duration: total,
          curve: Interval(
            hold.inMicroseconds / total.inMicroseconds,
            1,
            curve: AppMotion.emphasizedDecelerate,
          ),
        )
        .then((_) => _breathe());
  }

  void _breathe() {
    if (!mounted || !_breathes || MotionGuard.reduced(context)) return;
    // An even number of legs ends where it started; the last frame can land a
    // hair past it, so settle exactly at rest.
    _pulse.repeat(reverse: true, count: _breathLegs).then((_) {
      if (mounted) _pulse.value = 0;
    });
  }

  @override
  void dispose() {
    _fill.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'orders.progress_step'.tr(
        namedArgs: {
          'step': '${widget.step + 1}',
          'total': '${OrderStatus.progressSteps}',
        },
      ),
      child: ExcludeSemantics(
        // Up to ~4.6 s of hold + fill + breath repaint this small layer only.
        child: RepaintBoundary(
          child: SizedBox(
            height: AppSize.s4,
            width: double.infinity,
            child: CustomPaint(
              painter: TrackingProgressPainter(
                fill: _fill,
                pulse: _pulse,
                repaint: _repaint,
                current: widget.step,
                gap: AppSpacing.s4,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
