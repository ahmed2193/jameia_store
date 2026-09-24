import 'package:equatable/equatable.dart';

/// A recipe card of the jm3eia backend (home recipe rail, the "recipes using
/// this product" rail of a product page, the recipe list). [slug] opens it
/// (`GET /v1/recipes/:slug`). Text arrives already resolved for the request
/// language.
class RecipeSummaryEntity extends Equatable {
  const RecipeSummaryEntity({
    required this.id,
    required this.slug,
    required this.title,
    this.imageUrl = '',
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.servings = 0,
    this.cuisineName = '',
    this.dietName = '',
    this.excerpt = '',
  });

  final String id;
  final String slug;
  final String title;
  final String imageUrl;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;

  /// `''` when the recipe has no cuisine / diet label.
  final String cuisineName;
  final String dietName;

  /// One-line teaser; empty on the rails, which do not send it.
  final String excerpt;

  /// Prep + cook, what the card prints (`80 min`).
  int get totalMinutes => prepMinutes + cookMinutes;

  @override
  List<Object?> get props => [
    id,
    slug,
    title,
    imageUrl,
    prepMinutes,
    cookMinutes,
    servings,
    cuisineName,
    dietName,
    excerpt,
  ];
}
