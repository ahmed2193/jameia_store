import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';

/// JameiaMart branded splash motion. Shows the full-bleed brand splash art
/// ([AppConstants.splashImage]) on a white surface with a gentle entrance —
/// fade-in → rise → Ken-Burns scale-settle ([AppMotion.splashZoomBegin] → 1.0
/// across [AppMotion.splashKenBurns] on the [AppMotion.decelerate] curve) so the
/// art fades up, lifts and comes to rest just before navigation.
///
/// [onFinished] fires EXACTLY ONCE — when the entrance settles, or after a
/// failsafe elapses (whichever lands first), which drives the hand-off to the
/// next route.
///
/// Reduced-motion ([MotionGuard.reduced] / `disableAnimations`): the art is shown
/// statically and [onFinished] is invoked after a short fixed delay so navigation
/// still proceeds without any motion.
class SplashPlayer extends StatefulWidget {
  const SplashPlayer({super.key, required this.onFinished});

  /// Called once when the brand moment has settled — drives navigation.
  final VoidCallback onFinished;

  @override
  State<SplashPlayer> createState() => _SplashPlayerState();
}

class _SplashPlayerState extends State<SplashPlayer>
    with SingleTickerProviderStateMixin {
  /// Drives the fade + rise + Ken-Burns scale-settle over the full splash window.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.splashKenBurns,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: AppMotion.splashZoomBegin,
    end: 1,
  ).animate(CurvedAnimation(parent: _entrance, curve: AppMotion.decelerate));

  late final Animation<Offset> _rise = Tween<Offset>(
    begin: const Offset(0, 0.035),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: AppMotion.decelerate));

  bool _finished = false;

  /// Absolute failsafe: hands off even if the entrance controller never runs
  /// (e.g. it is never started). Idempotent via [_finishOnce], so the normal
  /// completion path wins; this only fires if nothing else did.
  Timer? _failsafe;

  /// Fires [SplashPlayer.onFinished] at most once.
  void _finishOnce() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void initState() {
    super.initState();
    // The Ken-Burns window is the upper bound: when the scale settles, hand off.
    _entrance.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finishOnce();
    });
    // Never let the app hang on the splash: hand off after twice the entrance
    // window even if the controller never completed.
    _failsafe = Timer(AppMotion.splashKenBurns * 2, _finishOnce);

    // Start after the first frame so the art is mounted before motion begins.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MotionGuard.reduced(context)) {
        // Static art; hand off after a short fixed beat so navigation still
        // proceeds with motion disabled.
        Future<void>.delayed(const Duration(milliseconds: 300), _finishOnce);
      } else {
        _entrance.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _failsafe?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MotionGuard.reduced(context);
    return ColoredBox(
      color: AppColors.white,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: reduced ? const AlwaysStoppedAnimation<double>(1) : _fade,
            child: SlideTransition(
              position: reduced
                  ? const AlwaysStoppedAnimation<Offset>(Offset.zero)
                  : _rise,
              child: ScaleTransition(
                scale:
                    reduced ? const AlwaysStoppedAnimation<double>(1) : _scale,
                child: RepaintBoundary(
                  child: Image.asset(
                    AppConstants.splashImage,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
