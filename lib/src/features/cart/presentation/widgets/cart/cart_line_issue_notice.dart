import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/cart_line_entity.dart';
import '../../../../../core/widgets/hero_tag.dart';

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
    final HeroTagTone tone;
    switch (issue) {
      case CartLineIssue.none:
        return const SizedBox.shrink();
      case CartLineIssue.outOfStock:
        text = 'cart.issue_out_of_stock'.tr();
        icon = HeroIcons.warning;
        tone = HeroTagTone.error;
      case CartLineIssue.quantityReduced:
        text = 'cart.issue_quantity_reduced'.tr();
        icon = HeroIcons.info;
        tone = HeroTagTone.neutral;
      case CartLineIssue.unavailable:
      case CartLineIssue.other:
        text = 'cart.issue_unavailable'.tr();
        icon = HeroIcons.warning;
        tone = HeroTagTone.error;
    }
    return HeroTag(label: text, icon: icon, tone: tone);
  }
}
