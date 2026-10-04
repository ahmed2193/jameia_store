import '../../../../core/domain/entities/order_entity.dart';
import '../../../../core/domain/entities/order_line_entity.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/invoice_language.dart';
import '../../domain/entities/order_invoice_summary.dart';
import '../../domain/entities/order_line_changes.dart';
import '../../domain/entities/order_payment_standing.dart';
import '../../domain/entities/order_type_label.dart';
import '../models/invoice_pdf_labels.dart';
import '../models/invoice_pdf_model.dart';

/// `OrderEntity` → the invoice PDF's content, written out in [InvoiceLanguage]
/// whatever language the app shows: names picked for that language, its
/// date pattern, its currency — and the server's own figures, never
/// recomputed (the rows come from [OrderInvoiceSummary], like the invoice
/// page's).
extension InvoicePdfMapper on OrderEntity {
  /// A price cell with no price (a free offer line).
  static const String _noFigure = '—';

  /// The minus of a deduction (U+2212, the width of a digit).
  static const String _minus = '−';

  InvoicePdfModel toInvoicePdfModel({
    required InvoiceLanguage language,
    required InvoicePdfLabels labels,
    required DateTime issuedAt,
  }) {
    final lc = language.code;
    final title = labels(InvoicePdfKeys.title);
    return InvoicePdfModel(
      rtl: language.isRtl,
      documentTitle: '$title $orderNumber',
      brandName: labels(InvoicePdfKeys.brand),
      title: title,
      orderNumber: orderNumber,
      stamp: _stampOf(OrderPaymentStanding.ofOrder(this), labels),
      details: InvoicePdfBlockModel(
        title: labels(InvoicePdfKeys.infoTitle),
        facts: _facts(lc, labels),
      ),
      recipient: _recipient(lc, labels),
      table: InvoicePdfTableModel(
        positionTitle: labels(InvoicePdfKeys.columnNumber),
        itemTitle: labels(InvoicePdfKeys.columnItem),
        quantityTitle: labels(InvoicePdfKeys.columnQuantity),
        unitPriceTitle: labels(InvoicePdfKeys.columnPrice, {
          'currency': Formatters.currencyIn(lc),
        }),
        totalTitle: labels(InvoicePdfKeys.columnTotal, {
          'currency': Formatters.currencyIn(lc),
        }),
        lines: _lines(lc, labels),
      ),
      summary: _summaryOf(OrderInvoiceSummary.of(this), lc, labels),
      thanks: labels(InvoicePdfKeys.thanks),
      issued: labels(InvoicePdfKeys.issued, {
        'date': Formatters.dateTime(lc, issuedAt),
      }),
      pageLabel: labels(InvoicePdfKeys.page),
    );
  }

  List<InvoicePdfFactModel> _facts(String lc, InvoicePdfLabels labels) {
    final slot = deliverySlot;
    final store = branch?.nameFor(lc) ?? '';
    return [
      InvoicePdfFactModel(labels(InvoicePdfKeys.number), orderNumber),
      if (createdAt != null)
        InvoicePdfFactModel(
          labels(InvoicePdfKeys.date),
          Formatters.dateTime(lc, createdAt),
        ),
      InvoicePdfFactModel(labels(InvoicePdfKeys.type), labels(typeLabelKey)),
      if (store.isNotEmpty)
        InvoicePdfFactModel(labels(InvoicePdfKeys.store), store),
      if (slot != null)
        InvoicePdfFactModel(
          labels(InvoicePdfKeys.slot),
          labels(InvoicePdfKeys.slotWindow, {
            'date': Formatters.dayMonth(lc, slot.day),
            'start': slot.start,
            'end': slot.end,
          }),
        ),
      InvoicePdfFactModel(
        labels(InvoicePdfKeys.payment),
        labels(payment.method.labelKey),
      ),
      InvoicePdfFactModel(
        labels(InvoicePdfKeys.status),
        labels(status.labelKey),
      ),
    ];
  }

  /// Delivery: the customer, the address, the phone to reach. Pickup (or an
  /// order without an address): the customer and how to reach them.
  InvoicePdfPartyModel _recipient(String lc, InvoicePdfLabels labels) {
    final address = isPickup ? null : this.address;
    final name = customer?.name.trim() ?? '';
    final phone = [address?.phone ?? '', customer?.phone ?? '']
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final email = customer?.email?.trim() ?? '';
    final lines = [
      if (address != null && name.isNotEmpty) address.label,
      ?address?.summary,
      phone,
      email,
    ].where((line) => line.isNotEmpty).toList();
    // No name on the order: the first line leads instead.
    final String heading;
    if (name.isNotEmpty) {
      heading = name;
    } else if (lines.isNotEmpty) {
      heading = lines.removeAt(0);
    } else {
      heading = branch?.nameFor(lc) ?? '';
    }
    return InvoicePdfPartyModel(
      title: labels(
        address == null ? InvoicePdfKeys.customer : InvoicePdfKeys.deliverTo,
      ),
      heading: heading,
      lines: lines,
    );
  }

  /// The paid lines as sold, then the free products of offers; one count
  /// runs through both.
  List<InvoicePdfLineModel> _lines(String lc, InvoicePdfLabels labels) {
    final changes = OrderLineChanges.of(picking);
    return [
      for (final (index, line) in lines.indexed)
        _paidLine(line, index + 1, changes, lc, labels),
      for (final (index, line) in offerLines.indexed)
        InvoicePdfLineModel(
          position: '${lines.length + index + 1}',
          name: line.nameFor(lc),
          note: line.offerNameFor(lc),
          noteTone: InvoicePdfTone.positive,
          quantity: '${line.quantity}',
          unitPrice: _noFigure,
          total: labels(InvoicePdfKeys.free),
          totalTone: InvoicePdfTone.positive,
        ),
    ];
  }

  static InvoicePdfLineModel _paidLine(
    OrderLineEntity line,
    int position,
    OrderLineChanges changes,
    String lc,
    InvoicePdfLabels labels,
  ) {
    final outcome = changes.outcomeOf(line.key);
    final substitute = changes.substitutionOf(line.key);
    final sku = line.sku ?? '';
    return InvoicePdfLineModel(
      position: '$position',
      name: line.nameFor(lc),
      detail: [
        line.variantNameFor(lc),
        if (sku.isNotEmpty) labels(InvoicePdfKeys.sku, {'sku': sku}),
      ].where((part) => part.isNotEmpty).join(Formatters.middot),
      note: switch (outcome) {
        OrderLineOutcome.kept => '',
        OrderLineOutcome.unavailable => labels(InvoicePdfKeys.unavailable),
        OrderLineOutcome.substituted =>
          substitute == null
              ? ''
              : labels(InvoicePdfKeys.replacedWith, {
                  'name': substitute.displayNameFor(lc),
                }),
      },
      noteTone: outcome == OrderLineOutcome.unavailable
          ? InvoicePdfTone.negative
          : InvoicePdfTone.positive,
      struck: outcome != OrderLineOutcome.kept,
      quantity: '${line.quantity}',
      unitPrice: Formatters.amount(line.unitPriceKd),
      total: Formatters.amount(line.lineTotalKd),
    );
  }

  static InvoicePdfSummaryModel _summaryOf(
    OrderInvoiceSummary summary,
    String lc,
    InvoicePdfLabels labels,
  ) {
    final points = summary.points;
    return InvoicePdfSummaryModel(
      title: labels(InvoicePdfKeys.summaryTitle),
      rows: [for (final charge in summary.charges) _rowOf(charge, labels)],
      totalLabel: labels(InvoicePdfKeys.total),
      // The label leads in both languages, like the app's money columns.
      totalAmount: Formatters.priceLtrIn(lc, summary.totalKd),
      notes: [
        if (summary.walletShareFils > 0)
          labels(InvoicePdfKeys.walletShare, {
            'amount': Formatters.priceLtrIn(lc, summary.walletShareKd),
          }),
        if (points != null)
          labels(
            points.pending
                ? InvoicePdfKeys.pointsPending
                : InvoicePdfKeys.pointsEarned,
            {'points': '${points.points}'},
          ),
      ],
    );
  }

  static InvoicePdfAmountModel _rowOf(
    InvoiceCharge charge,
    InvoicePdfLabels labels,
  ) {
    final label = labels(charge.kind.labelKey, {'code': charge.couponCode});
    if (charge.isFree) {
      return InvoicePdfAmountModel(
        label,
        labels(InvoicePdfKeys.free),
        tone: InvoicePdfTone.positive,
      );
    }
    final amount = Formatters.amount(charge.kd);
    return charge.isDeduction
        ? InvoicePdfAmountModel(
            label,
            '$_minus$amount',
            tone: InvoicePdfTone.positive,
          )
        : InvoicePdfAmountModel(label, amount);
  }

  static InvoicePdfStampModel _stampOf(
    OrderPaymentStanding standing,
    InvoicePdfLabels labels,
  ) => InvoicePdfStampModel(labels(standing.labelKey), switch (standing) {
    OrderPaymentStanding.paid => InvoicePdfTone.positive,
    OrderPaymentStanding.notCharged => InvoicePdfTone.negative,
    OrderPaymentStanding.dueOnDelivery ||
    OrderPaymentStanding.pending => InvoicePdfTone.warning,
  });
}
