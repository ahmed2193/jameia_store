import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/widgets/jameia_tag.dart';

/// Why the server flagged a line, as a tag in the line's row: red for a
/// line that cannot be bought, neutral for a quantity the server cut back;
/// nothing when it is fine.
class CartLineIssueNotice extends StatelessWidget {
  const CartLineIssueNotice({super.key, required this.issue});

  final CartLineIssue issue;

  @override
  Widget build(BuildContext context) {
    final String text;
    final IconData icon;
    final JameiaTagTone tone;
    switch (issue) {
      case CartLineIssue.none:
        return const SizedBox.shrink();
      case CartLineIssue.outOfStock:
        text = 'cart.issue_out_of_stock'.tr();
        icon = Icons.error_outline_rounded;
        tone = JameiaTagTone.error;
      case CartLineIssue.quantityReduced:
        text = 'cart.issue_quantity_reduced'.tr();
        icon = Icons.info_outline_rounded;
        tone = JameiaTagTone.neutral;
      case CartLineIssue.unavailable:
      case CartLineIssue.other:
        text = 'cart.issue_unavailable'.tr();
        icon = Icons.error_outline_rounded;
        tone = JameiaTagTone.error;
    }
    return JameiaTag(label: text, icon: icon, tone: tone);
  }
}
