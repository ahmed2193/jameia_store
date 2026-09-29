import 'package:flutter/widgets.dart';

import 'state_art.dart';
import 'state_loader_plate.dart';

/// [StateArt]'s frame while a state is still being worked out ("Checking
/// your connection…"): the branded dots on the 88 dp plate, placed exactly
/// where the art's disc will be — so the swap to the offline art (or back
/// to the screen) moves nothing.
class StateArtLoader extends StatelessWidget {
  const StateArtLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: StateArt.width,
      height: StateArt.height,
      child: Align(
        alignment: StateArt.discAlignment,
        child: StateLoaderPlate(),
      ),
    );
  }
}
