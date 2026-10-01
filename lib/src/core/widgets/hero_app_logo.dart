import 'package:flutter/widgets.dart';

import '../design/hero_assets.dart';

/// The Hero app icon ([HeroAssets.appLogo]) as a [size] square with rounded
/// corners ([radius]), decoded at the size shown (the source is far larger):
/// the store badge at the head of home, the order's store row, the about
/// logo. Its host adds any frame or shadow. Decorative: the words beside it
/// name the store.
class HeroAppLogo extends StatelessWidget {
  const HeroAppLogo({super.key, required this.size, required this.radius});

  final double size;

  /// The corner radius of the tile.
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    child: Image.asset(
      HeroAssets.appLogo,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      excludeFromSemantics: true,
    ),
  );
}
