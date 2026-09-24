// What the home screen actually draws: the backend's blocks after the strip
// that advertises a rail is folded into it, an expired strip is dropped and
// the category block is filled from the whole tree.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/features/home/data/mappers/home_feed_mapper.dart';
import 'package:jameia_mart/src/features/home/data/models/home_feed_model.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_feed.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_link.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/compose_home_feed_usecase.dart';

import 'home_test_fakes.dart';

final DateTime _now = DateTime.utc(2026, 9, 20, 12);

const ComposeHomeFeedUseCase _compose = ComposeHomeFeedUseCase();

HomeFeed _composed(HomeFeed feed, {DateTime? now}) =>
    _compose(ComposeHomeFeedParams(feed: feed, now: now ?? _now))
        .getOrElse(() => throw StateError('left'));

HomePromoStripSection _strip({
  String id = 'strip',
  String target = 'todays-deals',
  HomeLinkType type = HomeLinkType.collection,
  DateTime? endsAt,
}) => HomePromoStripSection(
  id: id,
  headline: 'Flash deals',
  link: HomeLink(type: type, target: target),
  theme: HomeSectionTheme.deals,
  endsAt: endsAt,
);

HomeProductRailSection _rail({
  String id = 'rail',
  String collectionSlug = 'todays-deals',
}) => HomeProductRailSection(
  id: id,
  products: const [],
  title: "Today's deals",
  collectionSlug: collectionSlug,
  theme: HomeSectionTheme.deals,
);

void main() {
  group('the live feed', () {
    final feed = HomeFeedModel.fromJson(liveHomeJson()).toEntity();

    test('folds the flash strip into the deals rail it links to', () {
      final composed = _composed(feed);

      // Eight blocks arrive; the strip and the rail it advertises are one.
      expect(feed.sections, hasLength(8));
      expect(composed.sections, hasLength(7));
      final block = composed.sections[2];
      expect(block, isA<HomeThemedBlockSection>());
      block as HomeThemedBlockSection;
      expect(block.strip.id, 'hs-flash');
      expect(block.rail.id, 'hs-todays-deals');
      // It takes the place of the earlier of the two.
      expect(
        [for (final section in composed.sections) section.id],
        [
          'hs-categories',
          'hs-occasions',
          'hs-flash',
          'hs-new-arrivals',
          'hs-on-sale',
          'hs-brands',
          'hs-recipes',
        ],
      );
      // The block wears the rail's heading and the deals colour.
      expect(block.title, "Today's deals");
      expect(block.theme, HomeSectionTheme.deals);
    });

    test('fills the category block with the aisles and their shelves', () {
      final composed = _composed(feed);
      final categories = composed.sections.first as HomeCategoryRailSection;
      final slugs = [for (final c in categories.categories) c.slug];

      // The live tree is 9 roots + 23 children + 6 deeper rows; the block
      // shows a category and its sub-categories, not the third level.
      expect(feed.categories.all, hasLength(38));
      expect(categories.categories, hasLength(32));
      expect(slugs, isNot(contains('apples')));
      expect(slugs.first, 'fresh-food');
      // A root is followed by its own children.
      expect(categories.categories[1].parentId, categories.categories[0].id);
      expect(categories.id, 'hs-categories');
    });
  });

  group('rules', () {
    final tree = CatalogCategoryTree(const [
      CatalogCategoryEntity(id: 'c1', slug: 'fresh-food', name: 'Fresh Food'),
      CatalogCategoryEntity(
        id: 'c2',
        slug: 'apples',
        name: 'Apples',
        parentId: 'c1',
      ),
    ]);

    test('an expired strip leaves the feed and takes no rail with it', () {
      final feed = HomeFeed(
        sections: [
          _strip(endsAt: _now.subtract(const Duration(minutes: 1))),
          _rail(),
        ],
        categories: tree,
      );

      final composed = _composed(feed);

      expect(composed.sections, hasLength(1));
      expect(composed.sections.single, isA<HomeProductRailSection>());
    });

    test('a strip that ends later still pairs', () {
      final feed = HomeFeed(
        sections: [
          _strip(endsAt: _now.add(const Duration(hours: 1))),
          _rail(),
        ],
        categories: tree,
      );

      expect(_composed(feed).sections.single, isA<HomeThemedBlockSection>());
    });

    test('a rail before its strip puts the block at the rail position', () {
      final feed = HomeFeed(sections: [_rail(), _strip()], categories: tree);

      final composed = _composed(feed);

      expect(composed.sections, hasLength(1));
      expect(composed.sections.single, isA<HomeThemedBlockSection>());
    });

    test('an unpaired strip and an unpaired rail are left alone', () {
      final feed = HomeFeed(
        sections: [
          _strip(target: 'nothing-like-it'),
          _rail(collectionSlug: 'other'),
          _strip(id: 'url-strip', type: HomeLinkType.url, target: 'https://x'),
        ],
        categories: tree,
      );

      final composed = _composed(feed);

      expect(composed.sections, hasLength(3));
      expect(composed.sections.whereType<HomeThemedBlockSection>(), isEmpty);
    });

    test('two strips on the same collection take different rails', () {
      final feed = HomeFeed(
        sections: [
          _strip(id: 's1'),
          _strip(id: 's2'),
          _rail(id: 'r1'),
          _rail(id: 'r2'),
        ],
        categories: tree,
      );

      final composed = _composed(feed);
      final blocks = composed.sections.whereType<HomeThemedBlockSection>();

      expect(blocks, hasLength(2));
      expect([for (final block in blocks) block.rail.id], ['r1', 'r2']);
    });

    test('an empty tree leaves the category block as the backend sent it', () {
      final section = HomeCategoryRailSection(
        id: 'cat',
        categories: const [
          CatalogCategoryEntity(id: 'x', slug: 'x', name: 'X'),
        ],
      );
      final feed = HomeFeed(
        sections: [section],
        categories: CatalogCategoryTree.empty,
      );

      expect(_composed(feed).sections.single, same(section));
    });

    test('composing changes nothing else about the feed', () {
      final feed = HomeFeed(sections: [_rail()], categories: tree);

      final composed = _composed(feed);

      expect(composed.slides, feed.slides);
      expect(composed.announcements, feed.announcements);
      expect(composed.categories, feed.categories);
      expect(
        ComposeHomeFeedParams(feed: feed, now: _now),
        ComposeHomeFeedParams(feed: feed, now: _now),
      );
    });

    test('the same feed and clock compose to the same screen', () {
      final feed = HomeFeed(sections: [_strip(), _rail()], categories: tree);

      expect(_composed(feed).sections, _composed(feed).sections);
    });
  });
}
