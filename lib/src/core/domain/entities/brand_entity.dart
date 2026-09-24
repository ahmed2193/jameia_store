import 'package:equatable/equatable.dart';

/// A brand of the jm3eia backend catalogue (home brand rail, brand listing,
/// the brand row of a product page). [slug] filters the product list
/// (`brandSlug`). Text arrives already resolved for the request language.
class BrandEntity extends Equatable {
  const BrandEntity({
    required this.id,
    required this.slug,
    required this.name,
    this.image = '',
    this.description = '',
  });

  final String id;
  final String slug;
  final String name;

  /// May be `''`: show [initial] instead.
  final String image;
  final String description;

  bool get hasImage => image.isNotEmpty;

  /// First character of [name], the logo placeholder.
  String get initial => name.isEmpty ? '' : name.substring(0, 1);

  @override
  List<Object?> get props => [id, slug, name, image, description];
}
