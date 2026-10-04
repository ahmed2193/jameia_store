// OrderEntity → the invoice PDF's content: the chosen language's words from
// its real i18n file, the server's figures written out, the receipt's rules
// (struck lines, replacements, free offer lines, deductions, notes).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_fulfillment_entities.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/orders/data/mappers/invoice_pdf_mapper.dart';
import 'package:hero_mart/src/features/orders/data/models/invoice_pdf_labels.dart';
import 'package:hero_mart/src/features/orders/data/models/invoice_pdf_model.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'invoice_test_fixtures.dart';

/// The real `orders.*` words of [code]'s i18n file.
InvoicePdfLabels _labels(String code) {
  final json = jsonDecode(File('assets/i18n/$code.json').readAsStringSync());
  final orders =
      (json as Map<String, dynamic>)['orders'] as Map<String, dynamic>;
  return InvoicePdfLabels({
    for (final MapEntry(:key, :value) in orders.entries)
      if (value is String) 'orders.$key': value,
  });
}

InvoicePdfModel _model(
  InvoiceLanguage language, {
  OrderStatus status = OrderStatus.delivered,
  OrderPaymentStatus paymentStatus = OrderPaymentStatus.paid,
  FulfillmentMode mode = FulfillmentMode.delivery,
  OrderCustomerEntity? customer = const OrderCustomerEntity(
    name: 'Ahmed Al-Fahad',
    phone: '+96550001111',
    email: 'ahmed@example.com',
  ),
}) =>
    fullInvoiceOrder(
      status: status,
      paymentStatus: paymentStatus,
      mode: mode,
      customer: customer,
    ).toInvoicePdfModel(
      language: language,
      labels: _labels(language.code),
      issuedAt: DateTime(2026, 10, 1, 21, 40),
    );

void main() {
  setUpAll(initializeDateFormatting);

  group('English', () {
    late InvoicePdfModel model;
    setUpAll(() => model = _model(InvoiceLanguage.english));

    test('the masthead, the stamp and the page words', () {
      expect(model.rtl, isFalse);
      expect(model.title, 'Invoice');
      expect(model.brandName, 'Hero');
      expect(model.documentTitle, 'Invoice HM-10234');
      expect(model.stamp.label, 'Paid');
      expect(model.stamp.tone, InvoicePdfTone.positive);
      expect(model.thanks, 'Thank you for shopping with Hero.');
      expect(model.issued, 'Downloaded on Oct 1, 2026 9:40 PM');
      expect(model.pageLabel, 'Page {page} of {pages}');
    });

    test('the order facts', () {
      final facts = {for (final f in model.details.facts) f.label: f.value};
      expect(facts['Order number'], 'HM-10234');
      expect(facts['Order type'], 'Express delivery');
      expect(facts['Store'], 'Salmiya');
      expect(facts['Scheduled for'], 'Sep 22 · 10:00 – 12:00');
      expect(facts['Payment'], 'Cash on delivery');
      expect(facts['Status'], 'Delivered');
      expect(facts, contains('Date'));
    });

    test('deliver to: the name over the address and how to reach them', () {
      expect(model.recipient.title, 'Deliver to');
      expect(model.recipient.heading, 'Ahmed Al-Fahad');
      expect(model.recipient.lines, [
        'البيت',
        'السالمية, قطعة 3, شارع 12, مبنى 7',
        '+96550001111',
        'ahmed@example.com',
      ]);
    });

    test('the table: currency in the titles, the receipt rules', () {
      final table = model.table;
      expect(table.unitPriceTitle, 'Price (KD)');
      expect(table.totalTitle, 'Total (KD)');
      expect(table.lines, hasLength(5));

      final first = table.lines[0];
      expect(first.position, '1');
      expect(first.detail, 'Full fat · SKU 6281007035316');
      expect(first.quantity, '2');
      expect(first.unitPrice, '0.450');
      expect(first.total, '0.900');
      expect(first.struck, isFalse);

      final replaced = table.lines[2];
      expect(replaced.struck, isTrue);
      expect(replaced.note, 'Replaced with Almarai Greek yoghurt 170g');
      expect(replaced.noteTone, InvoicePdfTone.positive);

      final unavailable = table.lines[3];
      expect(unavailable.struck, isTrue);
      expect(unavailable.note, 'Unavailable');
      expect(unavailable.noteTone, InvoicePdfTone.negative);

      final free = table.lines[4];
      expect(free.position, '5');
      expect(free.note, 'Buy 2 get 1 free');
      expect(free.unitPrice, '—');
      expect(free.total, 'Free');
      expect(free.totalTone, InvoicePdfTone.positive);
    });

    test('the summary: deductions with a minus, free delivery, the notes', () {
      final summary = model.summary;
      expect(summary.rows.map((row) => '${row.label}=${row.amount}'), [
        'Subtotal=12.500',
        'Offer discount=−0.250',
        'Pro discount=−0.300',
        'Coupon SAVE10=−0.500',
        'Loyalty points=−0.200',
        'Delivery fee=Free',
      ]);
      expect(summary.rows[1].tone, InvoicePdfTone.positive);
      expect(summary.totalLabel, 'Total');
      expect(summary.totalAmount, 'KD 11.250');
      expect(summary.notes, [
        'KD 2.000 paid from your wallet',
        'You earned 35 points',
      ]);
    });
  });

  group('Arabic', () {
    test('Arabic words, Arabic names, the currency after the amount', () {
      final model = _model(InvoiceLanguage.arabic);
      expect(model.rtl, isTrue);
      expect(model.title, 'الفاتورة');
      expect(model.brandName, 'هيرو');
      expect(model.table.unitPriceTitle, 'السعر (د.ك)');
      expect(model.table.lines.first.name, 'حليب المراعي كامل الدسم ١ لتر');
      expect(model.summary.totalAmount, 'د.ك 11.250');
      expect(model.summary.rows[2].label, 'خصم Pro');
      expect(model.pageLabel, 'صفحة {page} من {pages}');
      final facts = {for (final f in model.details.facts) f.label: f.value};
      expect(facts['الفرع'], 'السالمية');
    });
  });

  group('the stamp and the recipient follow the order', () {
    test('cash still to hand over → orange "Pay on delivery"', () {
      final model = _model(
        InvoiceLanguage.english,
        status: OrderStatus.outForDelivery,
        paymentStatus: OrderPaymentStatus.pending,
      );
      expect(model.stamp.label, 'Pay on delivery');
      expect(model.stamp.tone, InvoicePdfTone.warning);
      expect(
        model.summary.notes.last,
        "You'll earn 35 points once it's delivered",
      );
    });

    test('cancelled and unpaid → red "Not charged", no points', () {
      final model = _model(
        InvoiceLanguage.english,
        status: OrderStatus.cancelled,
        paymentStatus: OrderPaymentStatus.pending,
      );
      expect(model.stamp.label, 'Not charged');
      expect(model.stamp.tone, InvoicePdfTone.negative);
      expect(model.summary.notes, ['KD 2.000 paid from your wallet']);
    });

    test('pickup → the customer block, no address', () {
      final model = _model(
        InvoiceLanguage.english,
        mode: FulfillmentMode.pickup,
      );
      expect(model.recipient.title, 'Customer');
      expect(model.recipient.heading, 'Ahmed Al-Fahad');
      expect(model.recipient.lines, ['+96550001111', 'ahmed@example.com']);
      final facts = {for (final f in model.details.facts) f.label: f.value};
      expect(facts['Order type'], 'Pickup');
    });

    test('no customer on the order → the address leads', () {
      final model = _model(InvoiceLanguage.english, customer: null);
      expect(model.recipient.heading, 'السالمية, قطعة 3, شارع 12, مبنى 7');
      expect(model.recipient.lines, ['+96550001111']);
    });
  });
}
