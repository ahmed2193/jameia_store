import 'package:equatable/equatable.dart';

/// Framework-free VIP / Mart hero-card content entity (from store settings).
///
/// Carries the raw bilingual title/description; the [title] / [desc] getters
/// mirror the source DTO's "prefer English, else Arabic" fallback (not
/// locale-live — the VIP/Mart card picks the non-empty value).
class VipCardEntity extends Equatable {
  const VipCardEntity({
    this.titleEn = '',
    this.titleAr = '',
    this.descEn = '',
    this.descAr = '',
    this.image = '',
  });

  final String titleEn;
  final String titleAr;
  final String descEn;
  final String descAr;
  final String image;

  String get title => titleEn.isNotEmpty ? titleEn : titleAr;
  String get desc => descEn.isNotEmpty ? descEn : descAr;

  @override
  List<Object?> get props => [titleEn, titleAr, descEn, descAr, image];
}

/// Framework-free store-settings entity — the subset the home VIP/Mart card
/// needs (prep time + the two hero cards).
class StoreSettingsEntity extends Equatable {
  const StoreSettingsEntity({
    this.prepTime = 0,
    this.displayOrderAgain = false,
    this.displayBestSelling = false,
    this.vip = const VipCardEntity(),
    this.mart = const VipCardEntity(),
  });

  final int prepTime; // minutes — VIP/Mart "fast" card
  final bool displayOrderAgain;
  final bool displayBestSelling;
  final VipCardEntity vip;
  final VipCardEntity mart;

  @override
  List<Object?> get props => [
    prepTime,
    displayOrderAgain,
    displayBestSelling,
    vip,
    mart,
  ];
}
