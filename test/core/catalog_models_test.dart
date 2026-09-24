import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/models/brand_model.dart';
import 'package:jameia_mart/src/core/data/models/category_model.dart';
import 'package:jameia_mart/src/core/data/models/json_read.dart';
import 'package:jameia_mart/src/core/data/models/product_model.dart';
import 'package:jameia_mart/src/core/data/models/products_page_model.dart';
import 'package:jameia_mart/src/core/data/models/recipe_summary_model.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';

/// Payloads are copied from the live host (`api.jm3eia.store`, 2026-09-17).
const Map<String, dynamic> _riceCard = {
  '_id': '6aa6010d06da786e3f5658f9',
  'name': 'Basmati Rice 5kg',
  'slug': 'basmati-rice-5kg',
  'type': 'standard',
  'price': 3250,
  'proPrice': null,
  'compareAt': 4063,
  'image': 'https://images.unsplash.com/photo-1586201375761-83865001e31c',
  'stock': 80,
  'tags': ['fresh', 'best-seller'],
  'unitOfSale': 'piece',
  'ratingAverage': 5,
  'ratingCount': 1,
};

void main() {
  group('ProductModel.fromJson', () {
    test('parses a live product card', () {
      final model = ProductModel.fromJson(_riceCard);

      expect(model.id, '6aa6010d06da786e3f5658f9');
      expect(model.slug, 'basmati-rice-5kg');
      expect(model.name, 'Basmati Rice 5kg');
      expect(model.type, 'standard');
      expect(model.price, 3250);
      expect(model.proPrice, isNull);
      expect(model.compareAt, 4063);
      expect(model.stock, 80);
      expect(model.tags, ['fresh', 'best-seller']);
      expect(model.unitOfSale, 'piece');
      expect(model.ratingAverage, 5.0);
      expect(model.ratingCount, 1);
    });

    test('keeps the zero price of a variant product as sent', () {
      final model = ProductModel.fromJson({
        '_id': '6aa6010d06da786e3f5658f4',
        'slug': 'kdd-full-cream-milk',
        'type': 'variant',
        'price': 0,
        'compareAt': 100,
        'unitOfSale': 'l',
      });

      expect(model.type, 'variant');
      expect(model.price, 0);
      expect(model.unitOfSale, 'l');
    });

    test('falls back to defaults for missing or mistyped optionals', () {
      final model = ProductModel.fromJson({
        'id': 'p1',
        'slug': 'p-1',
        'price': '1250',
        'image': null,
        'tags': 'fresh',
        'ratingAverage': '4.5',
      });

      expect(model.id, 'p1');
      expect(model.name, '');
      expect(model.type, ProductModel.standardType);
      expect(model.price, 1250);
      expect(model.image, '');
      expect(model.tags, isEmpty);
      expect(model.unitOfSale, ProductModel.pieceUnit);
      expect(model.ratingAverage, 4.5);
    });

    test('throws without an id or a slug', () {
      expect(
        () => ProductModel.fromJson({'slug': 'x'}),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => ProductModel.fromJson({'_id': 'x'}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('ProductsPageModel.fromJson', () {
    test('parses data + pagination', () {
      final page = ProductsPageModel.fromJson({
        'data': [_riceCard],
        'pagination': {'total': 9, 'page': 2, 'limit': 4, 'hasMore': true},
      });

      expect(page.items.single.slug, 'basmati-rice-5kg');
      expect(page.total, 9);
      expect(page.page, 2);
      expect(page.limit, 4);
      expect(page.hasMore, isTrue);
    });

    test('skips a malformed row and keeps the rest', () {
      final page = ProductsPageModel.fromJson({
        'data': [
          {'name': 'no identity'},
          'not an object',
          _riceCard,
        ],
      }, requestedPage: 3);

      expect(page.items, hasLength(1));
      expect(page.page, 3);
      expect(page.hasMore, isFalse);
    });

    test('throws when data is not a list', () {
      expect(
        () => ProductsPageModel.fromJson({'data': null}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('CategoryModel.fromJson', () {
    test('parses a live child category', () {
      final model = CategoryModel.fromJson({
        '_id': '6aa5ffb85233feadc5c4150a',
        'name': 'Fruits & Vegetables',
        'slug': 'fruits-vegetables',
        'image': 'https://images.unsplash.com/photo-1610832958506-aa56368176cf',
        'parentId': '6aa5ffb85233feadc5c41509',
        'sortOrder': 0,
        'productCount': 8,
      });

      expect(model.slug, 'fruits-vegetables');
      expect(model.parentId, '6aa5ffb85233feadc5c41509');
      expect(model.productCount, 8);
    });

    test('a top-level category has no parent', () {
      final model = CategoryModel.fromJson({
        '_id': 'c1',
        'slug': 'fresh-food',
        'parentId': null,
      });

      expect(model.parentId, isNull);
      expect(model.image, '');
    });

    test('throws without a slug', () {
      expect(
        () => CategoryModel.fromJson({'_id': 'c1'}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('BrandModel.fromJson', () {
    test('parses the list shape and the description-less rail shape', () {
      final full = BrandModel.fromJson({
        '_id': '6aa5ffb85233feadc5c414fd',
        'name': 'Almarai',
        'slug': 'almarai',
        'image': 'https://images.unsplash.com/photo-1628088062854',
        'description': 'Leading dairy brand in the GCC.',
      });
      final rail = BrandModel.fromJson({
        '_id': '6aa6010d06da786e3f5658f0',
        'name': 'Nestlé',
        'slug': 'nestle',
        'image': '',
      });

      expect(full.description, 'Leading dairy brand in the GCC.');
      expect(rail.image, '');
      expect(rail.description, '');
    });
  });

  group('RecipeSummaryModel.fromJson', () {
    test('parses a live recipe card', () {
      final model = RecipeSummaryModel.fromJson({
        '_id': '6aa72210da383e2755e08d95',
        'slug': 'machboos',
        'title': 'Kuwaiti Chicken Machboos',
        'imageUrl': 'https://images.unsplash.com/photo-1555939594',
        'prepMinutes': 25,
        'cookMinutes': 55,
        'servings': 6,
        'cuisine': {'slug': 'kuwaiti', 'name': 'Kuwaiti'},
        'diet': {'slug': 'halal', 'name': 'Halal'},
      });

      expect(model.slug, 'machboos');
      expect(model.prepMinutes, 25);
      expect(model.cookMinutes, 55);
      expect(model.servings, 6);
      expect(model.cuisineName, 'Kuwaiti');
      expect(model.dietSlug, 'halal');
    });

    test('tolerates missing cuisine / diet', () {
      final model = RecipeSummaryModel.fromJson({'_id': 'r', 'slug': 's'});

      expect(model.cuisineName, '');
      expect(model.dietName, '');
    });
  });

  group('JsonRead', () {
    test('rows skips rows that throw and non-objects', () {
      final rows = JsonRead.rows<int>(
        [
          {'v': 1},
          7,
          {'v': 'bad'},
          {'v': 3},
        ],
        (json) {
          final value = json['v'];
          if (value is! int) throw const ParsingException('bad');
          return value;
        },
        logName: 'test',
      );

      expect(rows, [1, 3]);
    });

    test('dateTime parses ISO strings only', () {
      expect(
        JsonRead.dateTime('2026-09-13T01:49:14.169Z'),
        DateTime.utc(2026, 9, 13, 1, 49, 14, 169),
      );
      expect(JsonRead.dateTime(12), isNull);
    });
  });
}
