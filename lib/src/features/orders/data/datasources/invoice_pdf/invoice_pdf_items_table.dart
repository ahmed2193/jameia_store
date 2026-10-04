import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice_pdf_model.dart';
import 'invoice_pdf_cell.dart';
import 'invoice_pdf_header_cell.dart';
import 'invoice_pdf_item_cell.dart';
import 'invoice_pdf_style.dart';
import 'invoice_pdf_text.dart';

/// The items table: position, item, quantity, unit price and line total,
/// under a tinted header row that repeats on every page the table runs to.
/// It is a `Table` itself (not a widget around one) so the page layout can
/// split it between pages. The pdf table does not mirror on its own, so an
/// Arabic page gets its columns in reverse.
class InvoicePdfItemsTable extends pw.Table {
  InvoicePdfItemsTable(InvoicePdfTableModel table, InvoicePdfStyle style)
    : super(
        columnWidths: _ordered(_readingOrder, rtl: style.rtl).asMap(),
        border: pw.TableBorder(horizontalInside: _hairline, bottom: _hairline),
        children: [
          pw.TableRow(
            repeat: true,
            decoration: pw.BoxDecoration(color: InvoicePdfStyle.brandWash),
            children: _ordered(rtl: style.rtl, [
              InvoicePdfHeaderCell(
                table.positionTitle,
                style: style,
                align: InvoicePdfAlign.center,
              ),
              InvoicePdfHeaderCell(table.itemTitle, style: style),
              InvoicePdfHeaderCell(
                table.quantityTitle,
                style: style,
                align: InvoicePdfAlign.center,
              ),
              InvoicePdfHeaderCell(
                table.unitPriceTitle,
                style: style,
                align: InvoicePdfAlign.end,
              ),
              InvoicePdfHeaderCell(
                table.totalTitle,
                style: style,
                align: InvoicePdfAlign.end,
              ),
            ]),
          ),
          for (final line in table.lines)
            pw.TableRow(
              children: _ordered(rtl: style.rtl, [
                InvoicePdfCell(
                  line.position,
                  style: style,
                  size: InvoicePdfStyle.small,
                  color: InvoicePdfStyle.muted,
                  align: InvoicePdfAlign.center,
                ),
                InvoicePdfItemCell(line, style: style),
                InvoicePdfCell(
                  line.quantity,
                  style: style,
                  align: InvoicePdfAlign.center,
                ),
                InvoicePdfCell(
                  line.unitPrice,
                  style: style,
                  align: InvoicePdfAlign.end,
                ),
                InvoicePdfCell(
                  line.total,
                  style: style,
                  bold: true,
                  color: InvoicePdfStyle.colorOf(line.totalTone),
                  align: InvoicePdfAlign.end,
                ),
              ]),
            ),
        ],
      );

  static final pw.BorderSide _hairline = pw.BorderSide(
    color: InvoicePdfStyle.hairline,
    width: InvoicePdfStyle.hairlineWidth,
  );

  /// The columns in reading order: position, item, quantity, price, total.
  static const List<pw.TableColumnWidth> _readingOrder = [
    pw.FixedColumnWidth(InvoicePdfStyle.numberColumn),
    pw.FlexColumnWidth(),
    pw.FixedColumnWidth(InvoicePdfStyle.quantityColumn),
    pw.FixedColumnWidth(InvoicePdfStyle.priceColumn),
    pw.FixedColumnWidth(InvoicePdfStyle.totalColumn),
  ];

  /// [cells] in reading order, laid out the page's way.
  static List<T> _ordered<T>(List<T> cells, {required bool rtl}) =>
      rtl ? cells.reversed.toList() : cells;
}
