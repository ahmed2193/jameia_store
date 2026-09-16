import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../domain/entities/product_detail.dart';

/// Builds a fully-populated [ProductDetail] from DUMMY / seeded data so every
/// KeeMart PDP section renders like the reference screenshots, regardless of
/// what the tapped product happens to carry.
///
/// The hero is the tapped [Product] seeded with a 30%-off price, a 3-image
/// gallery, a "Frozen" storage spec, a pack weight and a calorie value. The
/// deals are seeded coupons with a rolling ~13-hour countdown. Similar / explore
/// / recipe imagery is drawn from the in-memory [KeetaRepository] catalogue so
/// the network thumbnails actually load and each card deep-links to a real
/// product.
abstract class ProductDetailsDummyDataSource {
  ProductDetail build(Product product);
}

class ProductDetailsDummyDataSourceImpl implements ProductDetailsDummyDataSource {
  ProductDetailsDummyDataSourceImpl(this.catalog);

  final KeetaRepository catalog;

  // Recommended-recipe seed (title, kcal, minutes) — the exact set from the
  // KeeMart reference. Images are borrowed from real catalogue products so they
  // load (no recipe photos ship with the app).
  static const List<(String, int, int)> _recipeSeed = [
    ('Risotto with Herbs and Sausage', 520, 30),
    ('Lemon Garlic Chicken Meatballs', 760, 30),
    ('Chicken with Chickpea Tagine', 650, 30),
    ('Beef Pilaf', 650, 60),
    ('Chicken in Rich Tomato Gravy', 750, 30),
    ('Middle Eastern Lentil and Meatball Soup', 650, 60),
    ('Beef Shawarma Rolls with Pomegranate', 1250, 25),
    ('Chicken & Chickpea Stew', 1000, 35),
  ];

  @override
  ProductDetail build(Product product) {
    final similar = _similar(product);
    final explore = _explore(product, similar);
    // Gallery: the hero image + up to two SAME-CATEGORY (similar) images so the
    // "Image 1/3" counter appears with related-looking photos.
    final gallery = _gallery(product, similar);
    final hero = _seedHero(product, gallery);

    return ProductDetail(
      product: hero,
      gallery: hero.resolvedGallery,
      kcal: hero.kcal,
      storage: hero.storage,
      weight: hero.weight,
      // Reference prep time; the ETA row derives the arrival clock from it.
      prepMinutes: catalog.settings.prepTime > 0 ? catalog.settings.prepTime : 10,
      brand: _brand(product),
      deals: _deals(hero),
      similar: similar,
      recipes: _recipes(_foodImages()),
      exploreMore: explore,
    );
  }

  // ── Hero (seed a discount / gallery / storage / weight / calories) ──────────
  Product _seedHero(Product p, List<String> gallery) {
    final original = p.hasDiscount
        ? p.originalPrice
        // ~30% off, rounded to 3dp (the app's currency precision).
        : double.parse((p.price / 0.7).toStringAsFixed(3));
    return p.copyWith(
      originalPrice: original,
      showDiscount: true,
      gallery: gallery,
      storage: p.storage.isNotEmpty ? p.storage : 'product.storage_frozen',
      weight: p.weight.isNotEmpty ? p.weight : _weightFromName(p.name),
      kcal: p.kcal > 0 ? p.kcal : 250,
    );
  }

  /// Up to three gallery images: the hero image + distinct same-category
  /// (similar) images (so the "Image 1/3" counter + Nutrition toggle appear).
  List<String> _gallery(Product p, List<Product> similar) {
    final out = <String>[if (p.image.isNotEmpty) p.image];
    for (final s in similar) {
      if (out.length >= 3) break;
      if (s.image.isNotEmpty && !out.contains(s.image)) out.add(s.image);
    }
    return out.isEmpty ? [p.image] : out;
  }

  // ── Seeded super-deals ──────────────────────────────────────────────────────
  List<DealVM> _deals(Product hero) {
    final pct = hero.discountPercent > 0 ? hero.discountPercent : 30;
    // Rolling ~13h13m window → the countdown reads like the reference "13:12:xx".
    final deadline = DateTime.now().add(const Duration(hours: 13, minutes: 13));
    DealVM deal(int minSpend) => DealVM(
          percent: pct,
          title: '',
          titleAr: '',
          subtitle: '',
          subtitleAr: '',
          minSpend: minSpend.toDouble(),
          deadline: deadline,
        );
    return [deal(5), deal(10)];
  }

  // ── Brand row (from the taxonomy) ───────────────────────────────────────────
  BrandInfo _brand(Product p) {
    final loc = catalog.locationOfSku(p.sku);
    final cat = loc == null ? null : catalog.categoryById(loc.categoryId);
    return BrandInfo(
      name: p.brand.isNotEmpty ? p.brand : (cat?.displayName ?? p.displayName),
      logo: (cat?.image.isNotEmpty ?? false) ? cat!.image : p.image,
      categoryId: loc?.categoryId ?? '',
    );
  }

  // ── Similar products (real, discounted-first, with a weight) ────────────────
  List<Product> _similar(Product p) {
    final same = catalog.allProducts
        .where((e) => e.id != p.id && e.categoryId == p.categoryId && e.image.isNotEmpty)
        .toList();
    final pool = same.isNotEmpty
        ? same
        : catalog.promoProducts.where((e) => e.id != p.id).toList();
    return _rank(pool).take(8).map(_withWeight).toList(growable: false);
  }

  // ── Explore more (promo products minus self + similar) ──────────────────────
  List<Product> _explore(Product p, List<Product> similar) {
    final seen = {p.id, ...similar.map((e) => e.id)};
    final pool = catalog.promoProducts
        .where((e) => !seen.contains(e.id) && e.image.isNotEmpty)
        .toList();
    final topped = pool.isNotEmpty
        ? pool
        : catalog.allProducts
            .where((e) => !seen.contains(e.id) && e.image.isNotEmpty)
            .toList();
    return _rank(topped).take(8).map(_withWeight).toList(growable: false);
  }

  // ── Recipes (seed titles/kcal/minutes + real catalogue images) ──────────────
  List<RecipeVM> _recipes(List<String> images) {
    return [
      for (var i = 0; i < _recipeSeed.length; i++)
        RecipeVM(
          image: images.isEmpty ? '' : images[i % images.length],
          title: _recipeSeed[i].$1,
          titleAr: '',
          kcal: _recipeSeed[i].$2,
          minutes: _recipeSeed[i].$3,
        ),
    ];
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// A spread of real catalogue image URLs (deduped) for the gallery + recipes.
  List<String> _images() {
    final out = <String>[];
    for (final p in catalog.allProducts) {
      if (p.image.isEmpty || out.contains(p.image)) continue;
      out.add(p.image);
      if (out.length >= 16) break;
    }
    return out;
  }

  // Non-food / non-appetising category keywords → skipped for recipe imagery
  // (kcal is mostly 0 in the catalogue, so filter by CATEGORY instead).
  static const List<String> _nonFoodCat = [
    'electronic', 'detergent', 'personal', 'make', 'cosmetic', 'stationery',
    'baby', 'cleaning', 'pet', 'supplies', 'tayebat', 'care', 'home', 'tissue',
    'drink', 'water', 'beverage', 'juice',
  ];
  // Most dish-like categories first, so recipe cards show real food photos.
  static const List<String> _preferCat = [
    'meat', 'frozen', 'bakery', 'dairy', 'snack', 'fruit', 'vegetable',
    'deli', 'cheese', 'ready', 'food',
  ];

  /// Food images for the recipe cards, drawn from appetising food categories
  /// (meat / frozen / bakery / dairy first) so a recipe card never shows soap or
  /// a water bottle. Falls back to the general pool only if too few are found.
  List<String> _foodImages() {
    int rank(String name) {
      final s = name.toLowerCase();
      for (var i = 0; i < _preferCat.length; i++) {
        if (s.contains(_preferCat[i])) return i;
      }
      return _preferCat.length;
    }

    final cats = catalog.categories
        .where((c) =>
            !_nonFoodCat.any((k) => c.name.toLowerCase().contains(k)))
        .toList()
      ..sort((a, b) => rank(a.name).compareTo(rank(b.name)));

    final out = <String>[];
    for (final c in cats) {
      for (final p in c.allProducts) {
        if (p.image.isEmpty || out.contains(p.image)) continue;
        out.add(p.image);
        if (out.length >= 16) break;
      }
      if (out.length >= 16) break;
    }
    if (out.length < _recipeSeed.length) {
      for (final img in _images()) {
        if (out.length >= _recipeSeed.length) break;
        if (!out.contains(img)) out.add(img);
      }
    }
    return out;
  }

  /// Discounted products first (so ribbons show), then the rest.
  List<Product> _rank(List<Product> pool) {
    final discounted = pool.where((e) => e.hasDiscount).toList();
    final rest = pool.where((e) => !e.hasDiscount).toList();
    return [...discounted, ...rest];
  }

  Product _withWeight(Product p) =>
      p.weight.isNotEmpty ? p : p.copyWith(weight: _weightFromName(p.name));

  static String _weightFromName(String name) {
    final m = RegExp(r'(\d+(?:\.\d+)?)\s?(g|kg|ml|l|pcs|L|ML|G|KG)\b')
        .firstMatch(name);
    if (m == null) return '';
    return '${m.group(1)} ${m.group(2)!.toLowerCase()}';
  }
}
