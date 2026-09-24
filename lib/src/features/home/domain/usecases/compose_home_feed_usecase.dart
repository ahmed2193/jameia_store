import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_category_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/home_feed.dart';
import '../entities/home_link.dart';
import '../entities/home_section_entity.dart';

class ComposeHomeFeedParams extends Equatable {
  const ComposeHomeFeedParams({required this.feed, required this.now});

  final HomeFeed feed;

  /// Decides whether a strip with an end date is still worth showing.
  final DateTime now;

  @override
  List<Object?> get props => [feed, now];
}

/// Turns the backend's flat block list into the blocks the screen draws, in
/// the backend's own order and without inventing anything:
///
///   * a promo strip whose countdown has run out leaves the feed;
///   * a strip and the rail it advertises become ONE themed block — the
///     backend joins them itself (the strip links to a collection and the rail
///     IS that collection), so this is a relation, not a guess from adjacency;
///   * the category block is filled from the whole tree the feed already
///     carries, so "shop by category" shows the shelves, not just the aisles.
///
/// Pure and synchronous: the same feed and the same clock always compose to
/// the same screen.
class ComposeHomeFeedUseCase
    implements SyncUseCase<HomeFeed, ComposeHomeFeedParams> {
  const ComposeHomeFeedUseCase();

  @override
  Either<Failure, HomeFeed> call(ComposeHomeFeedParams params) {
    final feed = params.feed;
    final live = <HomeSectionEntity>[
      for (final section in feed.sections)
        if (section is! HomePromoStripSection || section.isLiveAt(params.now))
          section,
    ];

    // Pair first, emit second: a rail may arrive before the strip that
    // advertises it, and the block belongs wherever the pair starts.
    final blockByMember = <String, HomeThemedBlockSection>{};
    for (final section in live) {
      if (section is! HomePromoStripSection) continue;
      final rail = _railFor(section, live, blockByMember.keys.toSet());
      if (rail == null) continue;
      final block = HomeThemedBlockSection(strip: section, rail: rail);
      blockByMember[section.id] = block;
      blockByMember[rail.id] = block;
    }

    final emitted = <String>{};
    final composed = <HomeSectionEntity>[];
    for (final section in live) {
      final block = blockByMember[section.id];
      if (block != null) {
        if (emitted.add(block.id)) composed.add(block);
        continue;
      }
      composed.add(
        section is HomeCategoryRailSection
            ? _withWholeTree(section, feed.categories)
            : section,
      );
    }

    return Right(
      HomeFeed(
        announcements: feed.announcements,
        slides: feed.slides,
        sections: composed,
        categories: feed.categories,
      ),
    );
  }

  /// The rail the strip links to: same collection, not yet taken by another
  /// strip.
  HomeProductRailSection? _railFor(
    HomePromoStripSection strip,
    List<HomeSectionEntity> sections,
    Set<String> taken,
  ) {
    if (strip.link.type != HomeLinkType.collection) return null;
    final slug = strip.link.target;
    if (slug.isEmpty) return null;
    for (final section in sections) {
      if (section is HomeProductRailSection &&
          section.collectionSlug == slug &&
          !taken.contains(section.id)) {
        return section;
      }
    }
    return null;
  }

  /// Every category the store has, parents first and their children right
  /// after them. Falls back to the block's own list when the tree is empty.
  HomeCategoryRailSection _withWholeTree(
    HomeCategoryRailSection section,
    CatalogCategoryTree tree,
  ) {
    if (tree.isEmpty) return section;
    final ordered = <CatalogCategoryEntity>[
      for (final root in tree.roots) ...[root, ...tree.childrenOf(root.id)],
    ];
    if (ordered.isEmpty) return section;
    return HomeCategoryRailSection(
      id: section.id,
      categories: ordered,
      title: section.title,
      icon: section.icon,
      accent: section.accent,
    );
  }
}
