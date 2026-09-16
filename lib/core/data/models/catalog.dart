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
  final String icon; // material icon name (mapped in widget) — fallback when no image
  final String color; // hex
  final String image; // real category image URL (KeeTa renders illustrated tiles)

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
  final int itemCount; // >0 → subtitle rendered as the localized "{n} items · shop now"
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

/// One card in the home "gathering" carousel (`gathering_card_v3`): a landscape
/// promo card (240×140, r16) with a price/subtitle band over a gradient.
class GatheringCard {
  final String id;
  final String title; // Arabic / default (source data)
  final String titleEn; // English counterpart
  final String subtitle; // Arabic / default
  final String subtitleEn; // English counterpart
  final String image;
  final double price; // 0 == hide price
  final String scheme; // deep-link target id (shop/channel)

  const GatheringCard({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.subtitle = '',
    this.subtitleEn = '',
    this.image = '',
    this.price = 0,
    this.scheme = '',
  });

  /// Locale-aware title / subtitle.
  String get displayTitle => _localized(titleEn, title);
  String get displaySubtitle => _localized(subtitleEn, subtitle);

  factory GatheringCard.fromJson(Map<String, dynamic> j) => GatheringCard(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        titleEn: j['titleEn'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        subtitleEn: j['subtitleEn'] as String? ?? '',
        image: j['image'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        scheme: j['scheme'] as String? ?? '',
      );
}

/// One tile in the horizontal "tiles area" row (`tiles_area`): a rectangular
/// category/banner tile (r5).
class HomeTile {
  final String id;
  final String title; // Arabic / default
  final String titleEn; // English counterpart
  final String image;
  final String bg; // hex fallback when no image
  final String scheme;

  const HomeTile({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.image = '',
    this.bg = '#FFFDE0',
    this.scheme = '',
  });

  /// Locale-aware title.
  String get displayTitle => _localized(titleEn, title);

  factory HomeTile.fromJson(Map<String, dynamic> j) => HomeTile(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        titleEn: j['titleEn'] as String? ?? '',
        image: j['image'] as String? ?? '',
        bg: j['bg'] as String? ?? '#FFFDE0',
        scheme: j['scheme'] as String? ?? '',
      );
}

/// One benefit in the sticky benefits bar (`new_user_sticky` / `old_user_sticky`):
/// an 18dp icon + 12dp colored label.
class BenefitItem {
  final String text; // Arabic / default
  final String textEn; // English counterpart
  final String icon; // material icon name (mapped in widget)
  final String color; // hex

  const BenefitItem({
    required this.text,
    this.textEn = '',
    this.icon = 'bolt',
    this.color = '#F0390E',
  });

  /// Locale-aware text.
  String get displayText => _localized(textEn, text);

  factory BenefitItem.fromJson(Map<String, dynamic> j) => BenefitItem(
        text: j['text'] as String? ?? '',
        textEn: j['textEn'] as String? ?? '',
        icon: j['icon'] as String? ?? 'bolt',
        color: j['color'] as String? ?? '#F0390E',
      );
}

/// A home popup/overlay descriptor (drives the popup queue). [type] selects the
/// renderer: `coupon` | `imageText` | `video` | `verticalBanner` | `newborn`.
class HomePopup {
  final String id;
  final String type;
  final String image;
  final String title; // Arabic / default
  final String titleEn; // English counterpart
  final String body; // Arabic / default
  final String bodyEn; // English counterpart
  final String ctaText; // Arabic / default
  final String ctaTextEn; // English counterpart
  final String scheme;
  // Voucher-ticket fields (coupon popup): left-panel amount + unit label.
  final String amount;
  final String amountUnit; // Arabic / default (e.g. "د.ك")
  final String amountUnitEn; // English counterpart (e.g. "KD")

  const HomePopup({
    required this.id,
    required this.type,
    this.image = '',
    this.title = '',
    this.titleEn = '',
    this.body = '',
    this.bodyEn = '',
    this.ctaText = '',
    this.ctaTextEn = '',
    this.scheme = '',
    this.amount = '',
    this.amountUnit = '',
    this.amountUnitEn = '',
  });

  /// Locale-aware title / body / CTA / amount unit.
  String get displayTitle => _localized(titleEn, title);
  String get displayBody => _localized(bodyEn, body);
  String get displayCta => _localized(ctaTextEn, ctaText);
  String get displayAmountUnit => _localized(amountUnitEn, amountUnit);

  factory HomePopup.fromJson(Map<String, dynamic> j) => HomePopup(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'imageText',
        image: j['image'] as String? ?? '',
        title: j['title'] as String? ?? '',
        titleEn: j['titleEn'] as String? ?? '',
        body: j['body'] as String? ?? '',
        bodyEn: j['bodyEn'] as String? ?? '',
        ctaText: j['ctaText'] as String? ?? '',
        ctaTextEn: j['ctaTextEn'] as String? ?? '',
        scheme: j['scheme'] as String? ?? '',
        amount: j['amount'] as String? ?? '',
        amountUnit: j['amountUnit'] as String? ?? '',
        amountUnitEn: j['amountUnitEn'] as String? ?? '',
      );
}
