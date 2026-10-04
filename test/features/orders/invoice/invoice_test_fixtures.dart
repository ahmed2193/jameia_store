import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_fulfillment_entities.dart';
import 'package:hero_mart/src/core/domain/entities/order_line_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_progress_entities.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_document.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';

/// The app's own bundle files, read from the repo (tests run at its root):
/// the real i18n strings, fonts and logo the invoice PDF uses.
class DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (!file.existsSync()) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(await file.readAsBytes());
  }
}

/// A line as sold.
OrderLineEntity invoiceLine(
  String key, {
  String nameEn = 'Almarai full fat milk 1L',
  String nameAr = 'حليب المراعي كامل الدسم ١ لتر',
  String variantEn = '',
  String variantAr = '',
  String? sku,
  int quantity = 1,
  int unitPriceFils = 450,
}) => OrderLineEntity(
  key: key,
  productId: 'p-$key',
  nameEn: nameEn,
  nameAr: nameAr,
  variantNameEn: variantEn,
  variantNameAr: variantAr,
  variantId: variantEn.isEmpty ? null : 'v-$key',
  sku: sku,
  quantity: quantity,
  unitPriceFils: unitPriceFils,
  lineTotalFils: unitPriceFils * quantity,
);

/// A delivered, paid, express delivery with every part an invoice can show:
/// an Arabic-named customer address, variants and SKUs, an unavailable and
/// a replaced line, a free offer product, every deduction, a wallet share
/// and earned points.
OrderEntity fullInvoiceOrder({
  OrderStatus status = OrderStatus.delivered,
  OrderPaymentStatus paymentStatus = OrderPaymentStatus.paid,
  OrderPaymentMethod method = OrderPaymentMethod.cod,
  FulfillmentMode mode = FulfillmentMode.delivery,
  List<OrderLineEntity>? lines,
  OrderCustomerEntity? customer = const OrderCustomerEntity(
    name: 'Ahmed Al-Fahad',
    phone: '+96550001111',
    email: 'ahmed@example.com',
  ),
}) => OrderEntity(
  id: 'o1',
  orderNumber: 'HM-10234',
  status: status,
  fulfillmentMode: mode,
  customer: customer,
  branch: const OrderPlaceEntity(
    id: 'b1',
    nameEn: 'Salmiya',
    nameAr: 'السالمية',
  ),
  address: const OrderAddressEntity(
    label: 'البيت',
    city: 'السالمية',
    block: 'قطعة 3',
    street: 'شارع 12',
    building: 'مبنى 7',
    phone: '+96550001111',
  ),
  lines:
      lines ??
      [
        invoiceLine(
          'l1',
          variantEn: 'Full fat',
          variantAr: 'كامل الدسم',
          sku: '6281007035316',
          quantity: 2,
        ),
        invoiceLine(
          'l2',
          nameEn: 'Lusine white sliced bread, large family pack',
          nameAr: 'خبز لوزين أبيض شرائح، عبوة عائلية كبيرة',
          quantity: 1,
          unitPriceFils: 600,
        ),
        invoiceLine(
          'l3',
          nameEn: 'Nadec Greek yoghurt 170g',
          nameAr: 'زبادي يوناني نادك ١٧٠ جم',
          quantity: 3,
          unitPriceFils: 350,
        ),
        invoiceLine(
          'l4',
          nameEn: 'KDD orange juice 1L',
          nameAr: 'عصير برتقال كي دي دي ١ لتر',
          quantity: 1,
          unitPriceFils: 750,
        ),
      ],
  offerLines: const [
    OrderOfferLineEntity(
      productId: 'p-free',
      offerId: 'of1',
      nameEn: 'Pepsi 330ml can',
      nameAr: 'بيبسي علبة ٣٣٠ مل',
      offerNameEn: 'Buy 2 get 1 free',
      offerNameAr: 'اشترِ ٢ واحصل على ١ مجانًا',
      quantity: 1,
    ),
  ],
  coupon: const OrderCouponEntity(code: 'SAVE10', discountFils: 500),
  loyalty: const OrderLoyaltyEntity(
    pointsRedeemed: 200,
    discountFils: 200,
    pointsEarned: 35,
  ),
  offerDiscountFils: 250,
  proDiscountFils: 300,
  subtotalFils: 12500,
  discountFils: 1250,
  deliveryFeeFils: 0,
  totalFils: 11250,
  express: true,
  deliverySlot: const OrderDeliverySlotEntity(
    templateId: 't1',
    date: '2026-09-22',
    start: '10:00',
    end: '12:00',
  ),
  payment: OrderPaymentEntity(
    method: method,
    status: paymentStatus,
    walletUsedFils: 2000,
  ),
  picking: const OrderPickingEntity(
    pickerName: 'Salem',
    unavailableLineKeys: ['l4'],
    substitutions: [
      OrderSubstitutionEntity(
        lineKey: 'l3',
        productNameEn: 'Almarai Greek yoghurt 170g',
        productNameAr: 'زبادي يوناني المراعي ١٧٠ جم',
      ),
    ],
  ),
  createdAt: DateTime.utc(2026, 9, 21, 7, 42),
);

/// [count] plain lines — enough to run the table on to more pages.
List<OrderLineEntity> manyInvoiceLines(int count) => [
  for (var i = 1; i <= count; i++)
    invoiceLine(
      'm$i',
      nameEn: 'Grocery item number $i with a fairly long product name',
      nameAr: 'منتج بقالة رقم $i باسم طويل نسبيًا',
      sku: '62810070$i',
      quantity: i % 4 + 1,
      unitPriceFils: 250 + i * 10,
    ),
];

/// A ready document (no layout behind it) for the presentation tests.
InvoiceDocument fakeInvoiceDocument({
  InvoiceLanguage language = InvoiceLanguage.english,
  int pageCount = 1,
  int size = 84 * 1024,
}) => InvoiceDocument(
  bytes: Uint8List(size),
  fileName: InvoiceDocument.fileNameFor('HM-10234', language),
  language: language,
  pageCount: pageCount,
);
