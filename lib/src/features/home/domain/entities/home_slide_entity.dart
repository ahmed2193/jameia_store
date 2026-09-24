import 'package:equatable/equatable.dart';

/// One slide of the home hero carousel. Text arrives already resolved for the
/// request language.
class HomeSlideEntity extends Equatable {
  const HomeSlideEntity({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.description = '',
  });

  final String id;
  final String imageUrl;
  final String title;
  final String description;

  bool get hasText => title.isNotEmpty || description.isNotEmpty;

  @override
  List<Object?> get props => [id, imageUrl, title, description];
}
