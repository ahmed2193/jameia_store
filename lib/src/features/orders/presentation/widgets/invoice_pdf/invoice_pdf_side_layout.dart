import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../invoice/invoice_export_actions.dart';
import '../invoice/invoice_file_card.dart';
import '../invoice/invoice_language_switch.dart';
import 'invoice_pdf_canvas.dart';

/// The invoice PDF on a screen wider than tall (a phone on its side, a
/// tablet across): the pages get the full height, and the language, the
/// file and the actions stand in a panel at the end — stacked, they would
/// leave the pages a sliver.
class InvoicePdfSideLayout extends StatelessWidget {
  const InvoicePdfSideLayout({super.key, required this.orderNumber});

  /// The narrowest landscape screen that takes the side panel.
  static const double _minWidth = AppSize.s520;
  static const double _panelWidth = AppSize.s320;

  final String orderNumber;

  /// Whether a screen of [size] gets this layout.
  static bool fits(Size size) =>
      size.width > size.height && size.width >= _minWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: InvoicePdfCanvas()),
        SizedBox(
          width: _panelWidth,
          child: SafeArea(
            left: false,
            right: false,
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(AppSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const InvoiceLanguageSwitch(),
                  const SizedBox(height: AppSpacing.s12),
                  InvoiceFileCard(orderNumber: orderNumber),
                  const SizedBox(height: AppSpacing.s16),
                  const InvoiceExportActions(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
