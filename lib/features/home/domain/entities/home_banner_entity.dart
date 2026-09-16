import 'package:equatable/equatable.dart';

/// Framework-free home-banner entity.
///
/// NOTE: the home feed's `banners` are rendered by the shared core
/// `BannerCarousel`, which still consumes the core `HomeBanner` DTO — so at that
/// boundary the core type is kept (see `HomeState.banners`). This entity exists
/// for completeness/parity with the other home modules and carries the raw
/// bilingual title (locale resolution would live in a display extension).
class HomeBannerEntity extends Equatable {
  const HomeBannerEntity({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.subtitle,
    this.itemCount = 0,
    required this.image,
    required this.bg,
  });

  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final int itemCount;
  final String image;
  final String bg; // hex

  @override
  List<Object?> get props =>
      [id, title, titleAr, subtitle, itemCount, image, bg];
}
