import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../motion/ambient_loop.dart';
import '../motion/motion.dart';
import 'state_art_layer.dart';
import 'state_art_part.dart';

/// A state illustration that tells its story (`StateArtMotions`): the still
/// plate [asset] with its moving [parts] stacked over it in the same frame,
/// all moved by one [AmbientLoop] — laps of [AppMotion.stateArtLap], as many
/// as fit [AppMotion.ambientBudget] (two), and only while it can be seen. At
/// rest (reduced motion, a screen reader, off screen, a hidden tab, the
/// budget spent) it is the still sticker; it plays again each time it comes
/// back on screen.
class StateArtScene extends StatelessWidget {
  const StateArtScene({
    super.key,
    required this.asset,
    required this.parts,
    required this.size,
    required this.unit,
  });

  final String asset;
  final List<StateArtPart> parts;
  final Size size;

  /// Logical pixels per plate unit.
  final double unit;

  @override
  Widget build(BuildContext context) {
    return AmbientLoop(
      period: AppMotion.stateArtLap,
      child: SvgPicture.asset(asset, width: size.width, height: size.height),
      builder: (context, loop, base) => RepaintBoundary(
        child: SizedBox.fromSize(
          size: size,
          child: Stack(
            children: [
              ?base,
              for (final part in parts)
                StateArtLayer(part: part, loop: loop, size: size, unit: unit),
            ],
          ),
        ),
      ),
    );
  }
}
