import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/widgets/hero_bidi_text.dart';

/// One fact of the invoice: a grey label over its value, and an optional
/// grey [detail] line under it (the address under its name, the wallet's
/// share under the payment method). Label over value, never side by side,
/// so a long value or large text wraps under its own label instead of
/// squeezing it. Values read in their own direction ([HeroBidiText]): a
/// Latin address in the Arabic app, an order code in either.
class InvoiceFactTile extends StatelessWidget {
  const InvoiceFactTile({
    super.key,
    required this.label,
    required this.value,
    this.detail = '',
    this.trailing,
  });

  final String label;
  final String value;

  /// Hidden when empty.
  final String detail;

  /// Right after the label and value (the order number's copy button), so
  /// it stays with its field however wide the tile is.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.meta),
                  const SizedBox(height: AppSpacing.s2),
                  HeroBidiText(value, style: AppTextStyles.label),
                  if (detail.isNotEmpty)
                    HeroBidiText(detail, style: AppTextStyles.meta),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
