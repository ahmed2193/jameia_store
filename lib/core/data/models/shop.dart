/// Shop / restaurant / grocery store and its menu — the central commerce model.
class Shop {
  final String id;
  final String name;
  final String logo;
  final String cover;
  final String kind; // restaurant | grocery
  final double rating;
  final int ratingCount;
  final double deliveryFee;
  final String deliveryTime;
  final double distanceKm;
  final double minOrder;
  final List<String> tags;
  final String promo;
  final bool freeDelivery;
  final bool sponsored;
  final List<MenuSection> sections;

  const Shop({
    required this.id,
    required this.name,
    required this.logo,
    required this.cover,
    required this.kind,
    required this.rating,
    required this.ratingCount,
    required this.deliveryFee,
    required this.deliveryTime,
    required this.distanceKm,
    required this.minOrder,
    required this.tags,
    required this.promo,
    required this.freeDelivery,
    required this.sponsored,
    required this.sections,
  });

  bool get isRestaurant => kind == 'restaurant';

  List<Product> get allProducts =>
      sections.expand((s) => s.products).toList(growable: false);

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
        id: j['id'] as String,
        name: j['name'] as String,
        logo: j['logo'] as String? ?? '',
        cover: j['cover'] as String? ?? '',
        kind: j['kind'] as String? ?? 'restaurant',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (j['ratingCount'] as num?)?.toInt() ?? 0,
        deliveryFee: (j['deliveryFee'] as num?)?.toDouble() ?? 0,
        deliveryTime: j['deliveryTime'] as String? ?? '',
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        minOrder: (j['minOrder'] as num?)?.toDouble() ?? 0,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        promo: j['promo'] as String? ?? '',
        freeDelivery: j['freeDelivery'] as bool? ?? false,
        sponsored: j['sponsored'] as bool? ?? false,
        sections: (j['sections'] as List?)
                ?.map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class MenuSection {
  final String title;
  final List<Product> products;

  const MenuSection({required this.title, required this.products});

  factory MenuSection.fromJson(Map<String, dynamic> j) => MenuSection(
        title: j['title'] as String? ?? '',
        products: (j['products'] as List?)
                ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final double originalPrice; // 0 == no discount
  final String desc;
  final int soldCount;
  final int kcal;

  const Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.desc,
    required this.soldCount,
    required this.kcal,
  });

  bool get hasDiscount => originalPrice > price && originalPrice > 0;

  int get discountPercent =>
      hasDiscount ? (((originalPrice - price) / originalPrice) * 100).round() : 0;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        image: j['image'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        originalPrice: (j['originalPrice'] as num?)?.toDouble() ?? 0,
        desc: j['desc'] as String? ?? '',
        soldCount: (j['soldCount'] as num?)?.toInt() ?? 0,
        kcal: (j['kcal'] as num?)?.toInt() ?? 0,
      );
}
