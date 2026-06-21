import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// M3 window-size breakpoints.
enum Breakpoint { compact, medium, expanded, large, extraLarge }

class Breakpoints {
  static const double compactMax = 600;
  static const double mediumMax = 840;
  static const double expandedMax = 1200;
  static const double largeMax = 1600;

  /// Default readable content width on wide screens.
  static const double contentMaxWidth = 720;

  /// Back-compat alias for the prior token name.
  static const double maxContentWidth = contentMaxWidth;

  static Breakpoint of(double width) {
    if (width < compactMax) return Breakpoint.compact;
    if (width < mediumMax) return Breakpoint.medium;
    if (width < expandedMax) return Breakpoint.expanded;
    if (width < largeMax) return Breakpoint.large;
    return Breakpoint.extraLarge;
  }

  static Breakpoint fromContext(BuildContext context) =>
      of(MediaQuery.sizeOf(context).width);

  /// Width content should size itself to: the real width on phones, clamped to
  /// [contentMaxWidth] on wider screens. Keeps proportional child sizes in step
  /// with a [ContentClamp] wrapper so tablet layouts don't compute widths
  /// against the full screen while the column itself is capped.
  static double contentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w < contentMaxWidth ? w : contentMaxWidth;
  }
}

extension BreakpointX on Breakpoint {
  bool get isCompact => this == Breakpoint.compact;
  bool get isMedium => this == Breakpoint.medium;
  bool get isExpanded => this == Breakpoint.expanded;
  bool get isLarge => this == Breakpoint.large;
  bool get isExtraLarge => this == Breakpoint.extraLarge;

  bool get isAtLeastMedium => index >= Breakpoint.medium.index;
  bool get isAtLeastExpanded => index >= Breakpoint.expanded.index;
  bool get isAtLeastLarge => index >= Breakpoint.large.index;
}

/// Debug overlay that shows the current [Breakpoint] name in the top-right
/// corner. Stripped at compile-time in release builds (kDebugMode guard).
class BreakpointOverlay extends StatelessWidget {
  const BreakpointOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    final bp = Breakpoints.fromContext(context);
    return Stack(
      children: [
        child,
        Positioned(
          top: 4,
          right: 4,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color.fromARGB(136, 0, 0, 0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  bp.name.toUpperCase(),
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 10,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
