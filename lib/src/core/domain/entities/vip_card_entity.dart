import 'package:equatable/equatable.dart';

/// VIP / Mart hero-card content (from store `settings.display.content`).
///
/// [title] / [desc] mirror the `VipCard` DTO's "prefer English, else Arabic"
/// fallback (not locale-driven — the card shows whichever value exists).
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
