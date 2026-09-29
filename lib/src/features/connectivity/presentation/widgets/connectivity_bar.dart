import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/collapse_reveal.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/shake_x.dart';
import '../../../../core/motion/tint_flash.dart';
import '../cubit/connectivity_banner_mode.dart';
import 'connectivity_bar_content.dart';

/// The banner itself: a strip under the status bar (only while the frame
/// gives it the inset) and the content row, which opens / closes with
/// [CollapseReveal]. The surface is a calm dark neutral while offline and
/// morphs to the brand green for "Back online", with one light wash.
/// A nudge shakes the row once. Painted in its own layer.
class ConnectivityBar extends StatelessWidget {
  const ConnectivityBar({
    super.key,
    required this.mode,
    required this.visible,
    required this.topInset,
    required this.nudges,
    required this.onClosed,
  });

  /// What to show (the last visible mode while closing).
  final ConnectivityBannerMode mode;
  final bool visible;

  /// The status-bar height while the bar holds it, else 0.
  final double topInset;
  final ValueListenable<int> nudges;
  final VoidCallback onClosed;

  static const double _washAlpha = 0.24;

  bool get _backOnline => mode == ConnectivityBannerMode.backOnline;

  @override
  Widget build(BuildContext context) {
    // White "Back online" text on `primary` green would be 2.3:1; the deep
    // brand green keeps it above 4.5:1.
    final surface = _backOnline
        ? AppColors.brandDeep
        : AppColors.offlineSurface;
    // Always in the tree (a closed bar has no height, so it claims no part of
    // the status bar): swapping the wrapper would remount the bar mid-open.
    // While the bar covers the status bar it asks for light icons.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: RepaintBoundary(
        child: TintFlash<bool>(
          value: _backOnline,
          when: (_, next) => next,
          color: AppColors.white,
          peakAlpha: _washAlpha,
          over: true,
          child: AnimatedContainer(
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: AppMotion.signature,
            color: surface,
            // The bar sits above the navigator, outside every page's
            // Scaffold. Its own Material gives the text the app theme's
            // style instead of the framework's fallback (yellow underline).
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topInset),
                  CollapseReveal(
                    visible: visible,
                    onClosed: onClosed,
                    child: ValueListenableBuilder<int>(
                      valueListenable: nudges,
                      builder: (context, count, content) =>
                          ShakeX(shakeKey: count, child: content!),
                      child: ConnectivityBarContent(mode: mode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
