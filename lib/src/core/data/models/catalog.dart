/// Home-surface models: KingKong icon grid, banners, and the user profile.
library;

import 'package:intl/intl.dart';

/// Locale-aware pick — the Arabic value when the active locale is Arabic and the
/// Arabic string is non-empty, else the English/default value. Mirrors
/// `shop.dart`'s `localizedCatalogName` so these data-driven home strings switch
/// with `Intl.defaultLocale` (synced by `LocalizationCubit` on every language
/// change). Callers pass `(english, arabic)`.
String _localized(String en, String ar) =>
    (Intl.defaultLocale ?? 'en').startsWith('ar') && ar.trim().isNotEmpty
    ? ar
    : en;

class KingKongItem {
  final String id;
  final String title; // English / default (from category name)
  final String titleAr; // Arabic counterpart (from category nameAr)
  final String
  icon; // material icon name (mapped in widget) — fallback when no image
  final String color; // hex
  final String
  image; // real category image URL (Hero renders illustrated tiles)

  const KingKongItem({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.icon,
    required this.color,
    this.image = '',
  });

  /// Locale-aware title.
  String get displayTitle => _localized(title, titleAr);

  bool get hasImage => image.isNotEmpty;

  factory KingKongItem.fromJson(Map<String, dynamic> j) => KingKongItem(
    id: j['id'] as String,
    title: j['title'] as String,
    titleAr: j['titleAr'] as String? ?? '',
    icon: j['icon'] as String? ?? 'grid_view',
    color: j['color'] as String? ?? '#FFE41F',
    image: j['image'] as String? ?? '',
  );
}

class HomeBanner {
  final String id;
  final String title; // English / default
  final String titleAr; // Arabic counterpart
  final String subtitle; // used for fallback JSON banners (no itemCount)
  final int
  itemCount; // >0 → subtitle rendered as the localized "{n} items · shop now"
  final String image;
  final String bg; // hex

  const HomeBanner({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.subtitle,
    this.itemCount = 0,
    required this.image,
    required this.bg,
  });

  /// Locale-aware title.
  String get displayTitle => _localized(title, titleAr);

  factory HomeBanner.fromJson(Map<String, dynamic> j) => HomeBanner(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    titleAr: j['titleAr'] as String? ?? '',
    subtitle: j['subtitle'] as String? ?? '',
    itemCount: (j['itemCount'] as num?)?.toInt() ?? 0,
    image: j['image'] as String? ?? '',
    bg: j['bg'] as String? ?? '#FFE41F',
  );
}

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String avatar;
  final String deliveryCode;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.deliveryCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    avatar: j['avatar'] as String? ?? '',
    deliveryCode: j['deliveryCode'] as String? ?? '',
  );
}
