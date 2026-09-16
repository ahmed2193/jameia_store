import 'package:equatable/equatable.dart';

/// Framework-free "tiles area" tile entity.
///
/// Source stores Arabic/default in [title], English in [titleEn]; the
/// active-locale pick lives in `presentation/util/home_tile_display.dart`.
class HomeTileEntity extends Equatable {
  const HomeTileEntity({
    required this.id,
    required this.title,
    this.titleEn = '',
    this.image = '',
    this.bg = '#FFFDE0',
    this.scheme = '',
  });

  final String id;
  final String title; // Arabic / default
  final String titleEn; // English counterpart
  final String image;
  final String bg; // hex fallback when no image
  final String scheme;

  @override
  List<Object?> get props => [id, title, titleEn, image, bg, scheme];
}
