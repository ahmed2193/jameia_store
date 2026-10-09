import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'state_art_part.dart';

/// One moving part of a state illustration, drawn over the still plate at
/// the plate's [size] and moved by the plate's [loop] ([StateArtPart]): a
/// paint-only transform and fade, never a rebuild of the picture.
class StateArtLayer extends StatelessWidget {
  const StateArtLayer({
    super.key,
    required this.part,
    required this.loop,
    required this.size,
    required this.unit,
  });

  final StateArtPart part;

  /// The plate's lap, 0 → 1 (0 = at rest).
  final Animation<double> loop;
  final Size size;

  /// Logical pixels per plate unit.
  final double unit;

  @override
  Widget build(BuildContext context) {
    Widget layer = SvgPicture.asset(
      part.asset,
      width: size.width,
      height: size.height,
    );
    if (part.moves) {
      layer = AnimatedBuilder(
        animation: loop,
        child: layer,
        builder: (context, child) => Transform(
          transform: part.transformAt(loop.value, unit),
          child: child,
        ),
      );
    }
    final opacity = part.opacity;
    if (opacity != null) {
      layer = FadeTransition(opacity: loop.drive(opacity), child: layer);
    }
    return layer;
  }
}
