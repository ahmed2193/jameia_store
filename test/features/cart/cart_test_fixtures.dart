import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';

/// The wire shape of a cart product (the catalogue card the backend embeds).
Map<String, dynamic> productJson({
  String id = 'p1',
  String slug = 'basmati-rice',
  String name = 'Basmati rice',
  int price = 1500,
  int stock = 12,
  String type = 'standard',
}) => <String, dynamic>{
  '_id': id,
  'slug': slug,
  'name': name,
  'type': type,
  'price': price,
  'image': 'https://cdn/$slug.png',
  'stock': stock,
  'tags': <String>['fresh', '507f1f77bcf86cd799439011'],
  'unitOfSale': 'piece',
  'ratingAverage': 4.5,
  'ratingCount': 20,
};

Map<String, dynamic> lineJson({
  String key = 'l1',
  String productId = 'p1',
  int quantity = 2,
  int unitPrice = 1500,
  int maxQuantity = 10,
  String? variantId,
  String? issue,
}) => <String, dynamic>{
  'key': key,
  'quantity': quantity,
  'maxQuantity': maxQuantity,
  'unitPrice': unitPrice,
  'lineTotal': unitPrice * quantity,
  'variantId': ?variantId,
  if (variantId != null) 'variantName': '1 L',
  'issue': ?issue,
  'product': productJson(id: productId),
};

Map<String, dynamic> cartJson({
  String cartToken = 'ct-1',
  List<Map<String, dynamic>>? lines,
  int? subtotal,
  int minOrder = 0,
  bool meetsMinOrder = true,
  bool branchOpen = true,
  bool capacityAvailable = true,
  Map<String, dynamic>? coupon,
  List<Map<String, dynamic>> offerLines = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> offerProgress = const <Map<String, dynamic>>[],
}) {
  final rows = lines ?? <Map<String, dynamic>>[lineJson()];
  final total =
      subtotal ??
      rows.fold<int>(0, (sum, row) => sum + (row['lineTotal'] as int? ?? 0));
  return <String, dynamic>{
    'cartToken': cartToken,
    'itemCount': rows.fold<int>(
      0,
      (sum, row) => sum + (row['quantity'] as int? ?? 0),
    ),
    'fulfillmentMode': 'delivery',
    'lines': rows,
    'offerLines': offerLines,
    'appliedOffers': const <Map<String, dynamic>>[],
    'offerProgress': offerProgress,
    'coupon': ?coupon,
    'loyalty': const <String, dynamic>{'pointsApplied': 0, 'discount': 0},
    'expressOffered': true,
    'expressSelected': false,
    'expressEtaMinutes': 30,
    'expressSurchargeOffered': 500,
    'branchOpen': branchOpen,
    'capacityAvailable': capacityAvailable,
    'totals': <String, dynamic>{
      'subtotal': total,
      'couponDiscount': 0,
      'loyaltyDiscount': 0,
      'offerDiscount': 0,
      'discount': 0,
      'deliveryFee': 500,
      'freeDelivery': false,
      'total': total + 500,
      'minOrder': minOrder,
      'meetsMinOrder': meetsMinOrder,
      'baseDeliveryFee': 500,
      'expressSurcharge': 0,
      'etaMinutes': 45,
    },
  };
}

const CatalogProductEntity testProduct = CatalogProductEntity(
  id: 'p1',
  slug: 'basmati-rice',
  name: 'Basmati rice',
  priceFils: 1500,
  stock: 12,
);

const CatalogProductEntity otherProduct = CatalogProductEntity(
  id: 'p2',
  slug: 'olive-oil',
  name: 'Olive oil',
  priceFils: 2500,
  stock: 8,
);
