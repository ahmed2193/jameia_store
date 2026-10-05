import 'package:flutter/material.dart';

import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/branded_dot_loader.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';

/// The pin fixed in the middle of the map picker, Glovo style in the Hero
/// colours: a round green head on a short tail with [glyph] in its middle
/// (the house, or the kind of place once it is known) — the shape of the
/// pin the live rider map puts on the customer's door — or, outside the
/// delivery area, the amber pin with the warning sign. While the address
/// under it is read ([reading]) the Hero dots circle in its head instead of
/// the glyph — the label over it waits for the words. It rises while the
/// map moves under it and drops back on a spring (a small bounce) when the
/// map settles. Decorative: the tooltip and the footer say where it points.
class PickerPin extends StatelessWidget {
  const PickerPin({
    super.key,
    required this.lifted,
    required this.outside,
    this.reading = false,
    this.glyph = HeroIcons.home,
  });

  final bool lifted;
  final bool outside;
  final bool reading;
  final IconData glyph;

  /// The art is 48 × 58 with the tip at 53 and the head's middle at 24, 22;
  /// it is drawn a little larger.
  static const double _artWidth = 48;
  static const double _scale = AppSize.s52 / _artWidth;
  static const double width = AppSize.s52;
  static const double height = 58 * _scale;
  static const double tip = 53 * _scale;
  static const double _headTop = 22 * _scale;
  static const double _glyph = AppSize.s24 * _scale;

  /// How high it rises while the map moves.
  static const double lift = AppSize.s14;

  @override
  Widget build(BuildContext context) {
    final spring = AppSprings.snappy;
    return AnimatedContainer(
      duration: MotionGuard.duration(context, spring.duration),
      curve: spring,
      transform: Matrix4.translationValues(0, lifted ? -lift : 0, 0),
      child: FadeThroughSwitcher(
        stateKey: outside,
        crossFade: true,
        child: outside
            ? const HeroSvgGlyph.art(
                HeroAssets.mapPinAway,
                size: width,
                height: height,
              )
            : SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    const HeroSvgGlyph.art(
                      HeroAssets.mapPinPicker,
                      size: width,
                      height: height,
                    ),
                    Positioned(
                      left: (width - _glyph) / 2,
                      top: _headTop - _glyph / 2,
                      width: _glyph,
                      height: _glyph,
                      child: FadeThroughSwitcher(
                        stateKey: reading,
                        crossFade: true,
                        child: reading
                            ? const BrandedDotLoader(size: _glyph)
                            : HeroIcon(glyph, size: _glyph),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
