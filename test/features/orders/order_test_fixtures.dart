/// The wire shape of an order (`GET /v1/orders/{id}`).
Map<String, dynamic> orderJson({
  String id = 'o1',
  String orderNumber = 'JM-1001',
  String status = 'placed',
  String fulfillmentMode = 'delivery',
  List<Map<String, dynamic>>? lines,
  int total = 3500,
  String paymentMethod = 'cod',
  String paymentStatus = 'pending',
  Map<String, dynamic>? cancellation,
  Map<String, dynamic>? picking,
  Map<String, dynamic>? delivery,
  Map<String, dynamic>? deliverySlot,
  int? etaMinutes = 45,
}) => <String, dynamic>{
  '_id': id,
  'orderNumber': orderNumber,
  'status': status,
  'statusTimeline': <Map<String, dynamic>>[
    <String, dynamic>{'at': '2026-09-21T09:00:00.000Z', 'status': 'placed'},
    <String, dynamic>{'at': 'not-a-date', 'status': 'confirmed'},
  ],
  'fulfillmentMode': fulfillmentMode,
  'branch': <String, dynamic>{
    'id': 'b1',
    'name': <String, dynamic>{'en': 'Salmiya', 'ar': 'السالمية'},
  },
  'zone': <String, dynamic>{
    'id': 'z1',
    'name': <String, dynamic>{'en': 'Block 3', 'ar': 'قطعة ٣'},
  },
  'address': <String, dynamic>{
    'id': 'a1',
    'label': 'Home',
    'city': 'Salmiya',
    'block': '3',
    'street': '12',
    'building': '7',
    'phone': '96550001111',
    'lat': 29.33,
    'lng': 48.07,
  },
  'lines': lines ?? <Map<String, dynamic>>[orderLineJson()],
  'offerLines': <Map<String, dynamic>>[],
  'appliedOffers': <Map<String, dynamic>>[],
  'loyalty': <String, dynamic>{
    'pointsRedeemed': 0,
    'discount': 0,
    'pointsEarned': 35,
  },
  'offerDiscount': 0,
  'proDiscount': 0,
  'subtotal': 3000,
  'discount': 0,
  'deliveryFee': 500,
  'total': total,
  'express': false,
  'deliverySlot': ?deliverySlot,
  'etaMinutes': ?etaMinutes,
  'payment': <String, dynamic>{
    'method': paymentMethod,
    'status': paymentStatus,
    'walletUsed': 0,
  },
  'picking': ?picking,
  'delivery': ?delivery,
  'cancellation': ?cancellation,
  'createdAt': '2026-09-21T09:00:00.000Z',
  'updatedAt': '2026-09-21T09:10:00.000Z',
};

Map<String, dynamic> orderLineJson({
  String key = 'l1',
  String productId = 'p1',
  int quantity = 2,
  int unitPrice = 1500,
  String? variantId,
}) => <String, dynamic>{
  'key': key,
  'product': <String, dynamic>{
    'id': productId,
    'name': <String, dynamic>{'en': 'Basmati rice', 'ar': 'أرز بسمتي'},
    'image': 'https://cdn/rice.png',
    'type': 'standard',
  },
  if (variantId != null)
    'variant': <String, dynamic>{
      'id': variantId,
      'name': <String, dynamic>{'en': '1 L', 'ar': '١ لتر'},
      'sku': 'SKU-1',
    },
  'quantity': quantity,
  'unitPrice': unitPrice,
  'lineTotal': unitPrice * quantity,
};

Map<String, dynamic> ordersPageJson({
  List<Map<String, dynamic>>? orders,
  int page = 1,
  bool hasMore = false,
  int total = 1,
}) => <String, dynamic>{
  'data': orders ?? <Map<String, dynamic>>[orderJson()],
  'pagination': <String, dynamic>{
    'total': total,
    'page': page,
    'limit': 20,
    'hasMore': hasMore,
  },
};
