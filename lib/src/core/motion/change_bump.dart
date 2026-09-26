import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'motion.dart';

/// "This changed": when [value] changes (never on mount) the child grows to
/// [peak] and settles back over [AppMotion.medium]; an optional [haptic]
/// fires with it (also under reduced motion — haptics are separate from the
/// visual gate). For UI that stays on screen while its value changes: a row
/// icon when a coupon lands, an offer turning "reached". Idle it is an
/// identity transform. The haptic is read from the new widget, so pass it
/// only for the direction that deserves one.
class ChangeBump extends StatefulWidget {
  const ChangeBump({
    super.key,
    required this.value,
    required this.child,
    this.peak = defaultPeak,
    this.haptic,
    this.alignment = AlignmentDirectional.center,
  });

  static const double defaultPeak = 1.15;

  final Object? value;
  final Widget child;
  final double peak;
  final HapticKind? haptic;
  final AlignmentGeometry alignment;

  @override
  State<ChangeBump> createState() => _ChangeBumpState();
}

class _ChangeBumpState extends State<ChangeBump>
    with SingleTickerProviderStateMixin {
  static const double _rest = 1;
  static const double _riseWeight = 40;
  static const double _settleWeight = 60;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  late Animation<double> _scale = _scaleFor(widget.peak);

  Animation<double> _scaleFor(double peak) => _controller.drive(
    TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: _rest,
          end: peak,
        ).chain(CurveTween(curve: AppMotion.signature)),
        weight: _riseWeight,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: peak,
          end: _rest,
        ).chain(CurveTween(curve: AppMotion.machEaseInOut)),
        weight: _settleWeight,
      ),
    ]),
  );

  @override
  void didUpdateWidget(ChangeBump oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.peak != widget.peak) _scale = _scaleFor(widget.peak);
    if (oldWidget.value == widget.value) return;
    final haptic = widget.haptic;
    if (haptic != null) Haptics.fire(haptic);
    if (!MotionGuard.reduced(context)) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    alignment: widget.alignment.resolve(Directionality.of(context)),
    child: widget.child,
  );
}
