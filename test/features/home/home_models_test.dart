// Home DTOs + mappers, fed with the payloads the live host really sends.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/features/home/data/mappers/home_bootstrap_mapper.dart';
import 'package:jameia_mart/src/features/home/data/mappers/home_feed_mapper.dart';
import 'package:jameia_mart/src/features/home/data/models/home_feed_model.dart';
import 'package:jameia_mart/src/features/home/data/models/home_init_model.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_icon.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_link.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_section_entity.dart';

import 'home_test_fakes.dart';

void main() {
  group('GET /v1/home (live payload)', () {
    final feed = HomeFeedModel.fromJson(liveHomeJson()).toEntity();

    test('keeps every block, in backend order, as its own section type', () {
      expect(
        [for (final section in feed.sections) section.id],
        [
          'hs-categories',
          'hs-occasions',
          'hs-flash',
          'hs-todays-deals',
          'hs-new-arrivals',
          'hs-on-sale',
          'hs-brands',
          'hs-recipes',
        ],
      );
      expect(feed.sections[0], isA<HomeCategoryRailSection>());
      expect(feed.sections[1], isA<HomePromoCardsSection>());
      expect(feed.sections[2], isA<HomePromoStripSection>());
      expect(feed.sections[3], isA<HomeProductRailSection>());
      expect(feed.sections[6], isA<HomeBrandRailSection>());
      expect(feed.sections[7], isA<HomeRecipeRailSection>());
    });

    test('slides, ticker and the category tree', () {
      expect(feed.slides, hasLength(3));
      expect(feed.slides.first.title, 'Fresh groceries, delivered fast');
      expect(feed.announcements, hasLength(3));
      expect(feed.announcements.first.icon.key, HomeIconKey.truck);
      expect(feed.categories.all, hasLength(38));
      expect(feed.categories.roots, hasLength(9));
      expect(feed.categories.roots.first.slug, 'fresh-food');
      expect(
        [
          for (final c in feed.categories.childrenOf(
            feed.categories.roots.first.id,
          ))
            c.slug,
        ],
        ['fruits-vegetables', 'meat-poultry', 'seafood'],
      );
    });

    test('a product rail carries its collection, theme, icon and accent', () {
      final deals = feed.sections[3] as HomeProductRailSection;

      expect(deals.title, "Today's deals");
      expect(deals.collectionSlug, 'todays-deals');
      expect(deals.hasViewAll, isTrue);
      expect(deals.theme, HomeSectionTheme.deals);
      expect(deals.layout, HomeRailLayout.slider);
      expect(deals.icon.key, HomeIconKey.sparkles);
      expect(deals.accent, HomeAccent.amber);
      expect(deals.products, hasLength(8));
      final rice = deals.products.first;
      expect(rice.slug, 'basmati-rice-5kg');
      expect(rice.priceFils, 3250);
      expect(rice.discountPercent, 20);
    });

    test('the variant product of a rail has no list price', () {
      final deals = feed.sections[3] as HomeProductRailSection;
      final milk = deals.products.firstWhere(
        (product) => product.slug == 'kdd-full-cream-milk',
      );

      expect(milk.type, CatalogProductType.variant);
      expect(milk.hasListPrice, isFalse);
      expect(milk.canQuickAdd, isFalse);
      expect(milk.tags, isNot(contains(matches(r'^[0-9a-f]{24}$'))));
    });

    test('promo cards map their link and the web gradient to an accent', () {
      final occasions = feed.sections[1] as HomePromoCardsSection;
      final weeknight = occasions.cards.first;

      expect(weeknight.title, 'Weeknight dinner');
      expect(
        weeknight.link,
        const HomeLink(type: HomeLinkType.collection, target: 'fresh-picks'),
      );
      expect(weeknight.icon.key, HomeIconKey.utensils);
      expect(weeknight.accent, HomeAccent.violet);
      expect(occasions.cards[1].link.type, HomeLinkType.category);
    });

    test('the promo strip keeps headline, badge, link and theme', () {
      final flash = feed.sections[2] as HomePromoStripSection;

      expect(flash.headline, 'Flash deals — up to 30% off');
      expect(flash.badge, 'Limited time');
      expect(flash.link.target, 'todays-deals');
      expect(flash.theme, HomeSectionTheme.deals);
      expect(flash.endsAt, isNull);
      expect(flash.isLiveAt(DateTime(2030)), isTrue);
    });
  });

  group('HomeFeedMapper rules', () {
    test('drops inactive blocks, empty rails and unknown types; sorts', () {
      final feed = HomeFeedModel.fromJson({
        'slides': [
          {'_id': 's2', 'imageUrl': 'https://x/2.png', 'sortOrder': 2},
          {'_id': 's0', 'imageUrl': 'https://x/0.png', 'status': 'archived'},
          {'_id': 's1', 'imageUrl': 'https://x/1.png', 'sortOrder': 1},
          {'_id': 'broken'},
        ],
        'sections': [
          {
            'id': 'late',
            'type': 'banner',
            'sortOrder': 9,
            'config': {'imageUrl': 'https://x/b.png', 'title': 'Hello'},
          },
          {
            'id': 'off',
            'type': 'banner',
            'status': 'inactive',
            'config': {'imageUrl': 'https://x/b.png'},
          },
          {
            'id': 'empty-rail',
            'type': 'rail',
            'config': {'source': 'products'},
            'data': <Object>[],
          },
          {'id': 'future', 'type': 'video_wall', 'config': <String, Object>{}},
          {
            'id': 'early',
            'type': 'promo_strip',
            'sortOrder': 1,
            'config': {
              'title': 'Sale',
              'linkType': 'teleport',
              'linkTarget': 'x',
              'endsAt': '2026-09-18T00:00:00.000Z',
            },
          },
        ],
        'announcement': {
          'enabled': false,
          'items': [
            {'id': 'a', 'text': 'hidden'},
          ],
        },
      }).toEntity();

      expect([for (final slide in feed.slides) slide.id], ['s1', 's2']);
      expect(
        [for (final section in feed.sections) section.id],
        ['early', 'late'],
      );
      final strip = feed.sections.first as HomePromoStripSection;
      expect(strip.link.type, HomeLinkType.none);
      expect(strip.link.isNavigable, isFalse);
      expect(strip.isLiveAt(DateTime.utc(2026, 9, 17)), isTrue);
      expect(strip.isLiveAt(DateTime.utc(2026, 9, 19)), isFalse);
      expect(feed.announcements, isEmpty);
      expect(feed.categories.isEmpty, isTrue);
    });

    test('an empty payload is an empty feed, not an error', () {
      final feed = HomeFeedModel.fromJson(const {}).toEntity();

      expect(feed.isEmpty, isTrue);
    });

    test('a custom icon wins over the library key', () {
      final feed = HomeFeedModel.fromJson({
        'sections': [
          {
            'id': 'b',
            'type': 'banner',
            'icon': {'source': 'custom', 'url': 'https://x/i.png'},
            'iconColor': 'mauve',
            'config': {'imageUrl': 'https://x/b.png'},
          },
        ],
      }).toEntity();

      expect(feed.sections.single.icon.isImage, isTrue);
      expect(feed.sections.single.accent, HomeAccent.none);
    });
  });

  group('GET /v1/init (live payload)', () {
    test('maps store, delivery zone and Pro perks', () {
      final bootstrap = HomeInitModel.fromJson(liveInitJson()).toEntity();

      expect(bootstrap.storeName, 'Jm3eia');
      expect(bootstrap.delivery?.mode, HomeDeliveryMode.delivery);
      expect(bootstrap.delivery?.zoneName, 'Salmiya & Sharq');
      expect(bootstrap.delivery?.placeName, 'Salmiya & Sharq');
      expect(bootstrap.delivery?.etaMinutes, 40);
      expect(bootstrap.delivery?.deliveryFeeFils, 650);
      expect(bootstrap.delivery?.minOrderKd, 2.5);
      expect(bootstrap.pro.enabled, isTrue);
      expect(bootstrap.pro.pointsMultiplier, 2);
      expect(bootstrap.pro.discountPercent, 5);
      expect(bootstrap.popups, isEmpty);
    });

    test(
      'pickup (or no zone) shows the branch; popups keep link + frequency',
      () {
        final bootstrap = HomeInitModel.fromJson({
          'delivery': {
            'mode': 'pickup',
            'branch': {'name': 'Salmiya'},
            'zone': null,
          },
          'content': {
            'popups': [
              {
                'id': 'pop1',
                'title': 'Ramadan',
                'ctaLabel': 'Shop',
                'linkType': 'collection',
                'linkTarget': 'ramadan',
                'frequency': 'day',
              },
              {'title': 'no id → dropped'},
            ],
          },
        }).toEntity();

        expect(bootstrap.delivery?.placeName, 'Salmiya');
        expect(bootstrap.popups.single.frequency, HomePopupFrequency.day);
        expect(bootstrap.popups.single.link.target, 'ramadan');
      },
    );

    test('an empty payload yields the defaults', () {
      final bootstrap = HomeInitModel.fromJson(const {}).toEntity();

      expect(bootstrap.delivery, isNull);
      expect(bootstrap.pro.enabled, isFalse);
    });
  });
}
