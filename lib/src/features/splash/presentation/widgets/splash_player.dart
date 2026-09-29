import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import 'splash_motion.dart';
import 'splash_scene_painter.dart';
import 'splash_status_bar.dart';
import 'splash_tagline.dart';
import 'splash_touch.dart';
import 'splash_touch_surface.dart';
import 'splash_variant.dart';
import 'splash_wordmark.dart';

/// Plays one Hero intro ([SplashVariant]) from the launch-screen frame to the
/// finished lockup, then calls [onFinished]. The bag delivers the name in the
/// app's language ([SplashWordmark]).
///
/// The first frame repeats the native splash exactly (the same bag in its
/// cape, centred, on the same green), so the hand-over from the OS splash
/// cannot be seen.
/// Nothing moves until that frame is really on screen: the clock starts
/// [SplashMotion.handOffHold] after the engine reports the first frame
/// rasterized (or after [SplashMotion.firstFrameWait] at most), so a slow
/// first frame or the OS splash's exit cross-fade never eats the opening.
/// The whole scene is one [CustomPaint] driven by one controller: it repaints
/// every frame without rebuilding widgets.
///
/// It also answers the finger ([SplashTouch]): a ring of colour where it
/// touches, the glow leaning towards it, a hop, a flick of the cape and a light
/// haptic when the bag is tapped. Touch never changes how long the intro
/// plays.
///
/// [onFinished] fires EXACTLY ONCE — when the intro ends, or after a failsafe
/// of twice its length (plus the start delay), whichever lands first. Reduced
/// motion shows the finished lockup straight away and hands off after
/// [SplashMotion.reducedHold].
///
/// [onLaunchFrame] fires once, when the launch frame is on screen and
/// holding still (at once under reduced motion): the moment to start the
/// first screen's data, so its load overlaps the intro (B1-14) and the work
/// it puts on this isolate lands while nothing moves yet.
class SplashPlayer extends StatefulWidget {
  const SplashPlayer({
    super.key,
    required this.variant,
    required this.onFinished,
    this.onLaunchFrame,
  });

  final SplashVariant variant;

  /// Called once when the intro is over — drives navigation.
  final VoidCallback onFinished;

  /// Called once when the launch frame holds, before the intro moves.
  final VoidCallback? onLaunchFrame;

  /// Longest time from the first frame to the start of the motion.
  static Duration get maxStartDelay =>
      SplashMotion.firstFrameWait + SplashMotion.handOffHold;

  @override
  State<SplashPlayer> createState() => _SplashPlayerState();
}

class _SplashPlayerState extends State<SplashPlayer>
    with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.variant.choreography.duration,
  );

  bool _started = false;
  bool _clockStarted = false;
  bool _finished = false;
  Timer? _failsafe;
  Timer? _reducedHold;
  Timer? _firstFrameWait;
  Timer? _handOffHold;

  /// Touch reactions; `null` under reduced motion.
  SplashTouch? _touch;

  void _finishOnce() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void initState() {
    super.initState();
    // Never let the app hang on the splash.
    _failsafe = Timer(
      widget.variant.choreography.duration * 2 + SplashPlayer.maxStartDelay,
      _finishOnce,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MotionGuard.reduced(context)) {
      _clock.value = 1;
      widget.onLaunchFrame?.call();
      _reducedHold = Timer(SplashMotion.reducedHold, _finishOnce);
      return;
    }
    _touch = SplashTouch(this);
    _clock.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finishOnce();
    });
    unawaited(
      WidgetsBinding.instance.waitUntilFirstFrameRasterized.then(
        (_) => _startAfterHold(),
      ),
    );
    _firstFrameWait = Timer(SplashMotion.firstFrameWait, _startAfterHold);
  }

  /// Holds the launch frame a beat, then runs the intro — once.
  void _startAfterHold() {
    if (_clockStarted || !mounted) return;
    _clockStarted = true;
    _firstFrameWait?.cancel();
    widget.onLaunchFrame?.call();
    _handOffHold = Timer(SplashMotion.handOffHold, () {
      if (mounted) _clock.forward();
    });
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    _reducedHold?.cancel();
    _firstFrameWait?.cancel();
    _handOffHold?.cancel();
    _touch?.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choreography = widget.variant.choreography;
    final wordmark = SplashWordmark.forLanguage(
      Localizations.localeOf(context).languageCode,
    );
    return SplashStatusBar(
      clock: _clock,
      choreography: choreography,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SplashTouchSurface(
            clock: _clock,
            choreography: choreography,
            wordmark: wordmark,
            touch: _touch,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: SplashScenePainter(
                  clock: _clock,
                  choreography: choreography,
                  wordmark: wordmark,
                  touch: _touch,
                ),
              ),
            ),
          ),
          SplashTagline(
            clock: _clock,
            choreography: choreography,
            wordmark: wordmark,
          ),
        ],
      ),
    );
  }
}
