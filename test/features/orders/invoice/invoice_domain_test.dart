// The invoice's domain rules: the document's name and language, the payment
// summary both the page and the PDF show, where the payment stands, and the
// small shared helpers the receipt reads.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_fulfillment_entities.dart';
import 'package:hero_mart/src/core/domain/entities/order_progress_entities.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_document.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_language.dart';
import 'package:hero_mart/src/features/orders/domain/entities/invoice_page_image.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_invoice_summary.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_payment_standing.dart';
import 'package:hero_mart/src/features/orders/domain/entities/order_type_label.dart';

import 'invoice_test_fixtures.dart';

void main() {
  group('InvoiceLanguage', () {
    test('Arabic for any ar locale, English for everything else', () {
      expect(InvoiceLanguage.of('ar'), InvoiceLanguage.arabic);
      expect(InvoiceLanguage.of('ar_KW'), InvoiceLanguage.arabic);
      expect(InvoiceLanguage.of('en'), InvoiceLanguage.english);
      expect(InvoiceLanguage.of('fr'), InvoiceLanguage.english);
      expect(InvoiceLanguage.arabic.isRtl, isTrue);
      expect(InvoiceLanguage.english.isRtl, isFalse);
    });
  });

  group('InvoiceDocument', () {
    test('the file name is Latin, safe and says its language', () {
      expect(
        InvoiceDocument.fileNameFor('HM-10234', InvoiceLanguage.english),
        'Hero-Invoice-HM-10234-EN.pdf',
      );
      expect(
        InvoiceDocument.fileNameFor(' HM/12 34 ', InvoiceLanguage.arabic),
        'Hero-Invoice-HM-12-34-AR.pdf',
      );
      expect(
        InvoiceDocument.fileNameFor('', InvoiceLanguage.english),
        'Hero-Invoice-EN.pdf',
      );
    });

    test('equality never walks the bytes', () {
      final a = fakeInvoiceDocument();
      final b = InvoiceDocument(
        bytes: Uint8List(a.sizeInBytes),
        fileName: a.fileName,
        language: a.language,
        pageCount: a.pageCount,
      );
      expect(a, b);
      expect(a.props, isNot(contains(a.bytes)));
    });
  });

  group('InvoicePageImage', () {
    test('its shape, and an equality that never walks the picture', () {
      final png = Uint8List(4);
      final page = InvoicePageImage(
        index: 0,
        png: png,
        width: 1654,
        height: 2339,
      );

      expect(page.aspectRatio, closeTo(InvoiceDocument.pageAspectRatio, 0.001));
      expect(
        page,
        InvoicePageImage(
          index: 0,
          png: Uint8List(4),
          width: 1654,
          height: 2339,
        ),
      );
      expect(page.props, isNot(contains(png)));
    });
  });

  group('OrderInvoiceSummary', () {
    test('every deduction that took something off, in the receipt order', () {
      final summary = OrderInvoiceSummary.of(fullInvoiceOrder());

      expect(summary.charges.map((charge) => charge.kind), [
        InvoiceChargeKind.subtotal,
        InvoiceChargeKind.offerDiscount,
        InvoiceChargeKind.proDiscount,
        InvoiceChargeKind.couponDiscount,
        InvoiceChargeKind.loyaltyDiscount,
        InvoiceChargeKind.deliveryFee,
      ]);
      expect(summary.charges[3].couponCode, 'SAVE10');
      expect(summary.charges.where((c) => c.isDeduction), hasLength(4));
      expect(summary.charges.last.isFree, isTrue);
      expect(summary.totalFils, 11250);
      expect(summary.totalKd, 11.25);
      expect(summary.walletShareFils, 2000);
      // offer 250 + Pro 300 + coupon 500 + points 200; a free fee is not a
      // saving.
      expect(summary.savedFils, 1250);
      expect(summary.savedKd, 1.25);
    });

    test('no deductions: the subtotal and the fee only', () {
      const order = OrderEntity(
        id: 'o1',
        orderNumber: 'HM-1',
        subtotalFils: 3000,
        deliveryFeeFils: 500,
        totalFils: 3500,
      );
      final summary = OrderInvoiceSummary.of(order);

      expect(summary.charges.map((charge) => charge.kind), [
        InvoiceChargeKind.subtotal,
        InvoiceChargeKind.deliveryFee,
      ]);
      expect(summary.charges.last.isFree, isFalse);
      expect(summary.charges.last.kd, 0.5);
      expect(summary.points, isNull);
      expect(summary.walletShareFils, 0);
      expect(summary.savedFils, 0);
    });

    test(
      'points: earned once delivered, pending on the way, none cancelled',
      () {
        expect(
          OrderInvoiceSummary.of(fullInvoiceOrder()).points,
          const InvoicePointsNote(points: 35, pending: false),
        );
        expect(
          OrderInvoiceSummary.of(fullInvoiceOrder(status: OrderStatus.picking))
              .points,
          const InvoicePointsNote(points: 35, pending: true),
        );
        expect(
          OrderInvoiceSummary.of(
            fullInvoiceOrder(status: OrderStatus.cancelled),
          ).points,
          isNull,
        );
      },
    );
  });

  group('OrderPaymentStanding', () {
    OrderPaymentStanding standing(
      OrderPaymentMethod method,
      OrderPaymentStatus status, {
      bool cancelled = false,
    }) => OrderPaymentStanding.of(
      OrderPaymentEntity(method: method, status: status),
      cancelled: cancelled,
    );

    test('paid, not charged, due on delivery, pending', () {
      expect(
        standing(OrderPaymentMethod.cod, OrderPaymentStatus.paid),
        OrderPaymentStanding.paid,
      );
      expect(
        standing(
          OrderPaymentMethod.cod,
          OrderPaymentStatus.pending,
          cancelled: true,
        ),
        OrderPaymentStanding.notCharged,
      );
      expect(
        standing(OrderPaymentMethod.cod, OrderPaymentStatus.pending),
        OrderPaymentStanding.dueOnDelivery,
      );
      expect(
        standing(OrderPaymentMethod.wallet, OrderPaymentStatus.pending),
        OrderPaymentStanding.pending,
      );
    });

    test('of an order: a cancelled one is "not charged"', () {
      expect(
        OrderPaymentStanding.ofOrder(
          fullInvoiceOrder(
            status: OrderStatus.cancelled,
            paymentStatus: OrderPaymentStatus.pending,
          ),
        ),
        OrderPaymentStanding.notCharged,
      );
      expect(
        OrderPaymentStanding.ofOrder(
          fullInvoiceOrder(
            status: OrderStatus.outForDelivery,
            paymentStatus: OrderPaymentStatus.pending,
          ),
        ),
        OrderPaymentStanding.dueOnDelivery,
      );
    });

    test('words shared by the pages and the PDF', () {
      expect(OrderPaymentStanding.paid.labelKey, 'orders.payment_paid');
      expect(
        OrderPaymentStanding.dueOnDelivery.labelKey,
        'orders.payment_due_on_delivery',
      );
      expect(
        InvoiceChargeKind.couponDiscount.labelKey,
        'orders.coupon_discount',
      );
      expect(InvoiceChargeKind.deliveryFee.labelKey, 'orders.delivery_fee');
    });
  });

  group('shared helpers', () {
    test("the wallet's share of a cash order", () {
      expect(
        const OrderPaymentEntity(
          method: OrderPaymentMethod.cod,
          walletUsedFils: 1500,
        ).walletShareFils,
        1500,
      );
      expect(
        const OrderPaymentEntity(
          method: OrderPaymentMethod.cod,
          walletUsedFils: 1500,
        ).walletShareKd,
        1.5,
      );
      expect(
        const OrderPaymentEntity(
          method: OrderPaymentMethod.wallet,
          walletUsedFils: 1500,
        ).walletShareFils,
        0,
      );
    });

    test('the order type: pickup wins over express', () {
      expect(
        fullInvoiceOrder(mode: FulfillmentMode.pickup).typeLabelKey,
        'orders.invoice_pdf_type_pickup',
      );
      expect(fullInvoiceOrder().typeLabelKey, 'orders.delivery_express');
      expect(
        const OrderEntity(id: 'o1', orderNumber: 'HM-1').typeLabelKey,
        'orders.invoice_pdf_type_delivery',
      );
    });

    test('payment method label keys', () {
      expect(OrderPaymentMethod.cod.labelKey, 'orders.payment_cod');
      expect(OrderPaymentMethod.wallet.labelKey, 'orders.payment_wallet');
      expect(OrderPaymentMethod.other.labelKey, 'orders.payment_other');
    });

    test('a replacement reads "Product · Variant"', () {
      const withVariant = OrderSubstitutionEntity(
        lineKey: 'l1',
        productNameEn: 'Milk',
        productNameAr: 'حليب',
        variantNameEn: '1L',
        variantNameAr: '١ لتر',
      );
      expect(withVariant.displayNameFor('en'), 'Milk · 1L');
      expect(withVariant.displayNameFor('ar'), 'حليب · ١ لتر');
      expect(
        const OrderSubstitutionEntity(
          lineKey: 'l1',
          productNameEn: 'Milk',
        ).displayNameFor('en'),
        'Milk',
      );
    });
  });
}
