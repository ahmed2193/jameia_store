import 'package:equatable/equatable.dart';

/// Framework-free category entity for the "Shop by category" home rail.
///
/// Home only renders the taxonomy top level (id / artwork / locale name), so the
/// entity carries just those raw fields — no nested sub-category/product graph.
/// Locale-live name resolution lives in `presentation/util/category_display.dart`.
class JameiaCategoryEntity extends Equatable {
  const JameiaCategoryEntity({
    required this.id,
    required this.name,
    this.nameAr = '',
    this.image = '',
  });

  final String id;
  final String name;
  final String nameAr;
  final String image;

  @override
  List<Object?> get props => [id, name, nameAr, image];
}
