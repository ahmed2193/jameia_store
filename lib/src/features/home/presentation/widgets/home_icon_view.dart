import 'package:flutter/material.dart';

import '../../../../core/design/hero_icon_tone.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/widgets/hero_icon.dart';
import '../../../../core/widgets/hero_image.dart';
import '../../domain/entities/home_icon.dart';

/// Draws a backend-chosen [HomeIcon]: the uploaded image, or the Hero glyph
/// of its library key — in [color], or two-tone in [tone] when one is given.
/// Draws nothing for an icon this build does not know.
class HomeIconView extends StatelessWidget {
  const HomeIconView({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    this.tone,
  });

  final HomeIcon icon;
  final double size;
  final Color color;
  final HeroIconTone? tone;

  static const Map<HomeIconKey, IconData> _glyphs = <HomeIconKey, IconData>{
    HomeIconKey.truck: HeroIcons.delivery,
    HomeIconKey.tag: HeroIcons.tag,
    HomeIconKey.zap: HeroIcons.bolt,
    HomeIconKey.gift: HeroIcons.gift,
    HomeIconKey.percent: HeroIcons.percent,
    HomeIconKey.shoppingBag: HeroIcons.bag,
    HomeIconKey.shoppingCart: HeroIcons.cart,
    HomeIconKey.store: HeroIcons.store,
    HomeIconKey.clock: HeroIcons.clock,
    HomeIconKey.calendar: HeroIcons.calendar,
    HomeIconKey.star: HeroIcons.star,
    HomeIconKey.heart: HeroIcons.heart,
    HomeIconKey.checkCircle: HeroIcons.checkCircle,
    HomeIconKey.info: HeroIcons.info,
    HomeIconKey.phone: HeroIcons.phone,
    HomeIconKey.mail: HeroIcons.mail,
    HomeIconKey.message: HeroIcons.chat,
    HomeIconKey.mapPin: HeroIcons.pin,
    HomeIconKey.home: HeroIcons.home,
    HomeIconKey.leaf: HeroIcons.leaf,
    HomeIconKey.utensils: HeroIcons.cutlery,
    HomeIconKey.chefHat: HeroIcons.recipe,
    HomeIconKey.coffee: HeroIcons.coffee,
    HomeIconKey.sparkles: HeroIcons.sparkle,
    HomeIconKey.flame: HeroIcons.flame,
    HomeIconKey.award: HeroIcons.crown,
    HomeIconKey.trendingUp: HeroIcons.trendingUp,
    HomeIconKey.megaphone: HeroIcons.megaphone,
  };

  @override
  Widget build(BuildContext context) {
    if (icon.isImage) {
      return HeroImage(
        url: icon.imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    final glyph = _glyphs[icon.key];
    if (glyph == null) return const SizedBox.shrink();
    final duo = tone;
    if (duo != null) return HeroIcon(glyph, tone: duo, size: size);
    return HeroIcon(glyph, size: size, color: color);
  }
}
