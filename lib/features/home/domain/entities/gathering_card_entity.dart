import 'package:equatable/equatable.dart';

/// Framework-free "gathering" carousel card entity.
///
/// Source data stores Arabic/default in [title]/[subtitle] and English in
/// [titleEn]/[subtitleEn]; the active-locale pick lives in
/// `presentation/util/gathering_card_display.dart`.
class GatheringCardEntity extends Equatable {
  const GatheringCardEntity({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.subtitle = '',
    this.subtitleEn = '',
    this.image = '',
    this.price = 0,
    this.scheme = '',
  });

  final String id;
  final String title; // Arabic / default
  final String titleEn; // English counterpart
  final String subtitle; // Arabic / default
  final String subtitleEn; // English counterpart
  final String image;
  final double price; // 0 == hide price
  final String scheme; // deep-link target id

  @override
  List<Object?> get props =>
      [id, title, titleEn, subtitle, subtitleEn, image, price, scheme];
}
