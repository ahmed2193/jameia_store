import 'package:flutter/material.dart';

import '../../../../core/widgets/jameia_image.dart';
import '../../domain/entities/home_icon.dart';

/// Draws a backend-chosen [HomeIcon]: the uploaded image, or the Material
/// glyph of its library key. Draws nothing for an icon this build does not
/// know.
class HomeIconView extends StatelessWidget {
  const HomeIconView({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  final HomeIcon icon;
  final double size;
  final Color color;

  static const Map<HomeIconKey, IconData> _glyphs = <HomeIconKey, IconData>{
    HomeIconKey.truck: Icons.local_shipping_outlined,
    HomeIconKey.tag: Icons.sell_outlined,
    HomeIconKey.zap: Icons.bolt_rounded,
    HomeIconKey.gift: Icons.card_giftcard_rounded,
    HomeIconKey.percent: Icons.percent_rounded,
    HomeIconKey.shoppingBag: Icons.shopping_bag_outlined,
    HomeIconKey.shoppingCart: Icons.shopping_cart_outlined,
    HomeIconKey.store: Icons.storefront_outlined,
    HomeIconKey.clock: Icons.schedule_rounded,
    HomeIconKey.calendar: Icons.calendar_today_outlined,
    HomeIconKey.star: Icons.star_outline_rounded,
    HomeIconKey.heart: Icons.favorite_border_rounded,
    HomeIconKey.checkCircle: Icons.check_circle_outline_rounded,
    HomeIconKey.info: Icons.info_outline_rounded,
    HomeIconKey.phone: Icons.phone_outlined,
    HomeIconKey.mail: Icons.mail_outline_rounded,
    HomeIconKey.message: Icons.chat_bubble_outline_rounded,
    HomeIconKey.mapPin: Icons.place_outlined,
    HomeIconKey.home: Icons.home_outlined,
    HomeIconKey.leaf: Icons.eco_outlined,
    HomeIconKey.utensils: Icons.restaurant_rounded,
    HomeIconKey.chefHat: Icons.soup_kitchen_outlined,
    HomeIconKey.coffee: Icons.coffee_outlined,
    HomeIconKey.sparkles: Icons.auto_awesome_outlined,
    HomeIconKey.flame: Icons.local_fire_department_outlined,
    HomeIconKey.award: Icons.workspace_premium_outlined,
    HomeIconKey.trendingUp: Icons.trending_up_rounded,
    HomeIconKey.megaphone: Icons.campaign_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (icon.isImage) {
      return JameiaImage(
        url: icon.imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    final glyph = _glyphs[icon.key];
    if (glyph == null) return const SizedBox.shrink();
    return Icon(glyph, size: size, color: color);
  }
}
