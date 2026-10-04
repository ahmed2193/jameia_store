// Every word the invoice PDF, its preview page and the invoice page read
// exists in both language files — the PDF can be written in the language
// the app does not show, so a gap would not be seen on screen first.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/orders/data/models/invoice_pdf_labels.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_invoice_summary.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_payment_standing.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_type_label.dart';

Map<String, dynamic> _orders(String code) =>
    (jsonDecode(File('assets/i18n/$code.json').readAsStringSync())
            as Map<String, dynamic>)['orders']
        as Map<String, dynamic>;

const List<String> _sheetKeys = [
  'invoice_pdf_download',
  'invoice_pdf_sheet_title',
  'invoice_pdf_sheet_subtitle',
  'invoice_pdf_language',
  'invoice_pdf_language_en',
  'invoice_pdf_language_ar',
  'invoice_pdf_preparing',
  'invoice_pdf_size',
  'invoice_pdf_failed',
  'invoice_pdf_save',
  'invoice_pdf_share',
  'invoice_pdf_print',
  'invoice_pdf_saved',
  'invoice_pdf_preview_failed',
];

// The invoice page's own words (the hero, the facts, the item rows).
const List<String> _pageKeys = [
  'total',
  'invoice_saved',
  'info_title',
  'invoice_number',
  'invoice_pdf_type',
  'invoice_pdf_slot',
  'eta_window_value',
  'invoice_payment',
  'payment_wallet_share',
  'deliver_to',
  'items_title',
  'invoice_each',
];

// A pickup, an express delivery and a plain one: every order type.
const List<OrderEntity> _orderTypes = [
  OrderEntity(
    id: 'o1',
    orderNumber: 'HM-1',
    fulfillmentMode: FulfillmentMode.pickup,
  ),
  OrderEntity(id: 'o2', orderNumber: 'HM-2', express: true),
  OrderEntity(id: 'o3', orderNumber: 'HM-3'),
];

void main() {
  final pdfKeys = <String>[
    ...InvoicePdfKeys.all,
    for (final status in OrderStatus.values) status.labelKey,
    for (final method in OrderPaymentMethod.values) method.labelKey,
    for (final standing in OrderPaymentStanding.values) standing.labelKey,
    for (final kind in InvoiceChargeKind.values) kind.labelKey,
    for (final order in _orderTypes) order.typeLabelKey,
  ];

  for (final code in ['en', 'ar']) {
    group(code, () {
      final orders = _orders(code);

      test('every PDF word is a plain string', () {
        for (final key in pdfKeys) {
          final name = key.substring('orders.'.length);
          expect(orders[name], isA<String>(), reason: '$code: $key');
          expect((orders[name] as String).trim(), isNotEmpty, reason: key);
        }
      });

      test('every preview word is there, the counts with plural forms', () {
        for (final key in _sheetKeys) {
          expect(orders[key], isA<String>(), reason: '$code: orders.$key');
        }
        for (final key in ['invoice_pdf_pages', 'item_count']) {
          final forms = orders[key];
          expect(forms, isA<Map<String, dynamic>>(), reason: '$code: $key');
          expect(
            (forms as Map<String, dynamic>).keys,
            containsAll(['one', 'other']),
            reason: '$code: $key',
          );
        }
        if (code == 'ar') {
          // Arabic counts: 3–10 take the plural, 11–99 the singular.
          expect(
            (orders['item_count'] as Map<String, dynamic>).keys,
            containsAll(['two', 'few', 'many']),
          );
        }
      });

      test('every page word is a plain string', () {
        for (final key in _pageKeys) {
          expect(orders[key], isA<String>(), reason: '$code: orders.$key');
        }
      });

      test('the templates keep their arguments', () {
        expect(orders['invoice_pdf_col_price'], contains('{currency}'));
        expect(orders['invoice_pdf_col_total'], contains('{currency}'));
        expect(orders['invoice_pdf_page'], contains('{page}'));
        expect(orders['invoice_pdf_page'], contains('{pages}'));
        expect(orders['invoice_pdf_issued'], contains('{date}'));
        expect(orders['invoice_pdf_sku'], contains('{sku}'));
        expect(orders['invoice_pdf_sheet_subtitle'], contains('{number}'));
        expect(orders['invoice_pdf_page'], contains('{pages}'));
        expect(orders['invoice_each'], contains('{price}'));
        expect(orders['invoice_saved'], contains('{amount}'));
      });
    });
  }
}
