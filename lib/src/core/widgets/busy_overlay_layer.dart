import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import 'loader_disc.dart';

/// What [BusyOverlay] lays over the route: the dim scrim fading in and the
/// white [LoaderDisc] springing up from a smaller disc just behind it.
/// Nothing under it takes a tap, and a screen reader hears only [label].
class BusyOverlayLayer extends StatelessWidget {
  const BusyOverlayLayer({
    super.key,
    required this.scrim,
    required this.disc,
    required this.done,
    this.label,
  });

  static const double _discFrom = 0.6;

  /// 0 → 1 as the scrim comes in (and back as it goes).
  final Animation<double> scrim;

  /// 0 → 1 (a touch past it on the spring) as the disc comes in.
  final Animation<double> disc;
  final bool done;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: label,
        child: AbsorbPointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              FadeTransition(
                opacity: scrim,
                child: const ColoredBox(color: AppColors.busyScrim),
              ),
              Center(
                child: FadeTransition(
                  opacity: scrim,
                  child: ScaleTransition(
                    scale: disc.drive(Tween<double>(begin: _discFrom, end: 1)),
                    child: LoaderDisc(done: done),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
