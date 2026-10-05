import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import 'picker_ground_mark.dart';
import 'picker_pin.dart';

/// The pin with its shadow on the ground, drawn around a zero-size origin so
/// the pin's tip is exactly there: put it in a [Center] over the point it
/// marks (the map picker's middle, the middle of the map preview).
class PickerPinMark extends StatelessWidget {
  const PickerPinMark({
    super.key,
    this.lifted = false,
    this.outside = false,
    this.reading = false,
    this.glyph = HeroIcons.home,
  });

  final bool lifted;
  final bool outside;

  /// The address under it is being read: the dots in its head.
  final bool reading;

  /// What the pin's head shows: the house, or the kind of place.
  final IconData glyph;

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -PickerGroundMark.box.width / 2,
            top: -PickerGroundMark.box.height / 2,
            width: PickerGroundMark.box.width,
            height: PickerGroundMark.box.height,
            child: Center(child: PickerGroundMark(lifted: lifted)),
          ),
          Positioned(
            left: -PickerPin.width / 2,
            top: -PickerPin.tip,
            child: PickerPin(
              lifted: lifted,
              outside: outside,
              reading: reading,
              glyph: glyph,
            ),
          ),
        ],
      ),
    );
  }
}
