import 'package:equatable/equatable.dart';

/// The backend's icon set for home sections, promo cards and the announcement
/// ticker. [other] = a name this build does not know yet (shows no icon).
enum HomeIconKey {
  truck,
  tag,
  zap,
  gift,
  percent,
  shoppingBag,
  shoppingCart,
  store,
  clock,
  calendar,
  star,
  heart,
  checkCircle,
  info,
  phone,
  mail,
  message,
  mapPin,
  home,
  leaf,
  utensils,
  chefHat,
  coffee,
  sparkles,
  flame,
  award,
  trendingUp,
  megaphone,
  other,
}

/// The backend's accent palette (`iconColor`, the colour family of a promo
/// card). [none] = not set → the widget uses its default.
enum HomeAccent { emerald, amber, rose, violet, sky, orange, zinc, none }

/// An icon chosen in the backend: one of the library [key]s, or an uploaded
/// image ([imageUrl] non-empty wins).
class HomeIcon extends Equatable {
  const HomeIcon({this.key = HomeIconKey.other, this.imageUrl = ''});

  final HomeIconKey key;
  final String imageUrl;

  bool get isImage => imageUrl.isNotEmpty;

  /// Nothing to draw: an unknown library key and no image.
  bool get isEmpty => !isImage && key == HomeIconKey.other;

  @override
  List<Object?> get props => [key, imageUrl];
}
