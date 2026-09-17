import 'package:flutter/material.dart';

/// Clamps the OS text-scale to a sane band so a 200% accessibility setting can't
/// shatter layouts. Apply ONCE, above `MaterialApp`'s content (via
/// `MaterialApp.builder`). Per the responsive skill: `TextScaler` only, clamped.
///
/// NOTE: this rebuilds the ambient scaler as a fresh LINEAR scaler from its
/// clamped effective factor instead of using `MediaQuery.withClampedTextScaling`.
/// That standard helper constructs a nested `_ClampedTextScaler` whose strict
/// `maxScale > minScale` assertion TRIPS when the ambient scaler is already
/// clamped (e.g. on MIUI / some OEM skins), which would red-screen the whole
/// app. This linear-rebuild approach is robust across platforms.
class TextScalerClamp extends StatelessWidget {
  const TextScalerClamp({
    super.key,
    required this.child,
    this.minScaleFactor = 1.0,
    this.maxScaleFactor = 1.3,
  });

  final Widget child;
  final double minScaleFactor;
  final double maxScaleFactor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final factor = mq.textScaler.scale(100.0) / 100.0;
    final clamped = factor.clamp(minScaleFactor, maxScaleFactor);
    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(clamped)),
      child: child,
    );
  }
}
