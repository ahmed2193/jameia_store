import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash_choreography.dart';

/// Light status-bar icons while the top of the splash is brand green, dark
/// ones once a scene has turned it white (the burst). Rebuilds only when that
/// flips, not on every frame.
class SplashStatusBar extends StatefulWidget {
  const SplashStatusBar({
    super.key,
    required this.clock,
    required this.choreography,
    required this.child,
  });

  final Animation<double> clock;
  final SplashChoreography choreography;
  final Widget child;

  static final SystemUiOverlayStyle _onBrand = SystemUiOverlayStyle.light
      .copyWith(statusBarColor: Colors.transparent);
  static final SystemUiOverlayStyle _onWhite = SystemUiOverlayStyle.dark
      .copyWith(statusBarColor: Colors.transparent);

  @override
  State<SplashStatusBar> createState() => _SplashStatusBarState();
}

class _SplashStatusBarState extends State<SplashStatusBar> {
  late bool _brandTop = _brandTopNow();

  @override
  void initState() {
    super.initState();
    widget.clock.addListener(_onTick);
  }

  @override
  void didUpdateWidget(SplashStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clock != widget.clock) {
      oldWidget.clock.removeListener(_onTick);
      widget.clock.addListener(_onTick);
    }
  }

  @override
  void dispose() {
    widget.clock.removeListener(_onTick);
    super.dispose();
  }

  bool _brandTopNow() => widget.choreography.isBrandTopAt(
    widget.clock.value * widget.choreography.duration.inMilliseconds,
  );

  void _onTick() {
    final brandTop = _brandTopNow();
    if (brandTop == _brandTop || !mounted) return;
    setState(() => _brandTop = brandTop);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: _brandTop ? SplashStatusBar._onBrand : SplashStatusBar._onWhite,
    child: widget.child,
  );
}
