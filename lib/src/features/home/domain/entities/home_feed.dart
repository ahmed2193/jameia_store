import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';
import 'home_announcement_item.dart';
import 'home_section_entity.dart';
import 'home_slide_entity.dart';

/// The home screen as the backend composes it (`GET /v1/home`): the
/// announcement ticker, the hero slides, the ordered content blocks and the
/// full category tree ("view all categories").
class HomeFeed extends Equatable {
  const HomeFeed({
    this.announcements = const <HomeAnnouncementItem>[],
    this.slides = const <HomeSlideEntity>[],
    this.sections = const <HomeSectionEntity>[],
    required this.categories,
  });

  static final HomeFeed empty = HomeFeed(categories: CatalogCategoryTree.empty);

  /// Empty when the backend switched the ticker off.
  final List<HomeAnnouncementItem> announcements;
  final List<HomeSlideEntity> slides;

  /// Active, non-empty blocks in display order.
  final List<HomeSectionEntity> sections;
  final CatalogCategoryTree categories;

  /// Nothing to show at all (the page renders the empty state).
  bool get isEmpty => slides.isEmpty && sections.isEmpty;

  @override
  List<Object?> get props => [announcements, slides, sections, categories];
}
