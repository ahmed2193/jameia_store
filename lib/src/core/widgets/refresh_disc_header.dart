import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import '../responsive/app_size.dart';
import 'refresh_disc.dart';

/// Where a pull-to-refresh stands, as [BrandedRefresh] reads it off the
/// platform indicator.
enum RefreshDiscPhase { idle, pulling, armed, refreshing, done, canceled }

/// The disc a pull brings down from under the top edge ([BrandedRefresh]):
/// it follows the finger — fading in, growing, its dots swapping as the pull
/// nears the threshold — swells a little once a release would refresh,
/// settles at its rest line and loops while the refresh runs, then shrinks
/// away; a pull let go too early slides it back up. Taps pass through.
class RefreshDiscHeader extends StatefulWidget {
  const RefreshDiscHeader({super.key, required this.pull, required this.phase});

  /// Room the header takes under the edge (the disc, its rest line and the
  /// stretch past it).
  static const double extent = AppSize.s120;

  /// The pull: 0 at the edge, 1 where a release refreshes, up to 1.5.
  final ValueListenable<double> pull;
  final ValueListenable<RefreshDiscPhase> phase;

  @override
  State<RefreshDiscHeader> createState() => _RefreshDiscHeaderState();
}

class _RefreshDiscHeaderState extends State<RefreshDiscHeader>
    with TickerProviderStateMixin {
  /// The disc's top at rest, below the edge.
  static const double _restTop = AppSize.s24;

  /// How far the disc follows a pull past the threshold (rubber band).
  static const double _beyond = 0.35;
  static const double _scaleFrom = 0.6;
  static const double _armedScale = 1.1;

  /// Half a loop (one swap) by the threshold.
  static const double _dotsPerPull = 0.5;

  /// 0: hidden just above the edge → 1: at rest.
  late final AnimationController _travel = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppMotion.loaderOrbit,
  );
  late final AnimationController _leave = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );
  late final Animation<double> _pullDots = _travel.drive(
    Tween<double>(begin: 0, end: _dotsPerPull),
  );

  /// What moves the disc frame to frame.
  late final Listenable _frame = Listenable.merge([_travel, _leave]);
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    widget.pull.addListener(_onPull);
    widget.phase.addListener(_onPhase);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MotionGuard.reduced(context);
  }

  @override
  void didUpdateWidget(RefreshDiscHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pull != widget.pull) {
      oldWidget.pull.removeListener(_onPull);
      widget.pull.addListener(_onPull);
    }
    if (oldWidget.phase != widget.phase) {
      oldWidget.phase.removeListener(_onPhase);
      widget.phase.addListener(_onPhase);
    }
  }

  @override
  void dispose() {
    widget.pull.removeListener(_onPull);
    widget.phase.removeListener(_onPhase);
    _travel.dispose();
    _loop.dispose();
    _leave.dispose();
    super.dispose();
  }

  Duration _motion(Duration duration) => _reduced ? Duration.zero : duration;

  void _onPull() {
    final phase = widget.phase.value;
    if (phase != RefreshDiscPhase.pulling && phase != RefreshDiscPhase.armed) {
      return;
    }
    final pull = widget.pull.value;
    _travel.value = pull <= 1 ? pull : 1 + (pull - 1) * _beyond;
  }

  void _onPhase() {
    switch (widget.phase.value) {
      case RefreshDiscPhase.pulling:
        _loop.stop();
        _leave.value = 0;
        _travel.value = 0;
      case RefreshDiscPhase.refreshing:
        unawaited(
          _travel.animateTo(
            1,
            duration: _motion(AppMotion.fast),
            curve: AppMotion.signature,
          ),
        );
        // The loop picks up where the pull left the dots.
        _loop.value = _pullDots.value % 1;
        if (!_reduced) unawaited(_loop.repeat());
      case RefreshDiscPhase.done:
        _leave.duration = _motion(AppMotion.medium);
        _leave.forward(from: 0).whenCompleteOrCancel(_reset);
      case RefreshDiscPhase.canceled:
        _travel
            .animateTo(
              0,
              duration: _motion(AppMotion.medium),
              curve: AppMotion.exit,
            )
            .whenCompleteOrCancel(_reset);
      case RefreshDiscPhase.armed || RefreshDiscPhase.idle:
        break;
    }
  }

  /// Back to hidden once the disc has gone.
  void _reset() {
    if (!mounted) return;
    final phase = widget.phase.value;
    if (phase == RefreshDiscPhase.pulling) return;
    _loop.stop();
    _travel.value = 0;
    _leave.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ClipRect(
          child: SizedBox(
            height: RefreshDiscHeader.extent,
            // The disc is rebuilt on a phase change only (which clock its dots
            // follow, the armed swell); a frame of the pull just moves, fades
            // and scales the same disc.
            child: ValueListenableBuilder<RefreshDiscPhase>(
              valueListenable: widget.phase,
              builder: (context, phase, _) => AnimatedBuilder(
                animation: _frame,
                builder: (context, disc) {
                  final travel = _travel.value;
                  if (travel <= 0) return const SizedBox.shrink();
                  final shown = travel.clamp(0.0, 1.0);
                  final gone = AppMotion.exit.transform(_leave.value);
                  return Stack(
                    children: [
                      PositionedDirectional(
                        top:
                            -RefreshDisc.diameter +
                            (RefreshDisc.diameter + _restTop) * travel,
                        start: 0,
                        end: 0,
                        child: Center(
                          child: Opacity(
                            opacity: shown * (1 - gone),
                            child: Transform.scale(
                              scale:
                                  (_scaleFrom + (1 - _scaleFrom) * shown) *
                                  (1 - gone),
                              child: disc,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: AnimatedScale(
                  scale: phase == RefreshDiscPhase.armed ? _armedScale : 1,
                  duration: _motion(AppMotion.fast),
                  curve: AppMotion.emphasized,
                  child: RepaintBoundary(
                    child: RefreshDisc(
                      dots:
                          phase == RefreshDiscPhase.refreshing ||
                              phase == RefreshDiscPhase.done
                          ? _loop
                          : _pullDots,
                    ),
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
