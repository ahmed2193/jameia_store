import 'package:equatable/equatable.dart';

/// Framework-free KingKong entry-grid tile entity.
///
/// Carries the raw bilingual title so `presentation/util/kingkong_display.dart`
/// resolves the active-locale label live. Hex colour stays a string.
class KingKongItemEntity extends Equatable {
  const KingKongItemEntity({
    required this.id,
    required this.title,
    this.titleAr = '',
    required this.icon,
    required this.color,
    this.image = '',
  });

  final String id;
  final String title;
  final String titleAr;
  final String icon; // material icon name (mapped in widget)
  final String color; // hex
  final String image;

  bool get hasImage => image.isNotEmpty;

  @override
  List<Object?> get props => [id, title, titleAr, icon, color, image];
}
