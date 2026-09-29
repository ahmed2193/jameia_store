import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../domain/entities/faq_item.dart';
import 'support_faq_header.dart';
import 'support_faq_row.dart';
import 'support_section_card.dart';

/// The hub's "Frequently asked" card: one chevron row per topic; the rows
/// cascade in once ([EntranceCascade]) when the topics arrive on a settled
/// page.
class SupportFaqList extends StatelessWidget {
  const SupportFaqList({super.key, required this.faqs});

  final List<FaqItem> faqs;

  @override
  Widget build(BuildContext context) {
    return EntranceCascade(
      child: SupportSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.only(
                start: AppSpacing.s12,
                top: AppSpacing.s12,
                bottom: AppSpacing.s4,
              ),
              child: SupportFaqHeader(),
            ),
            for (var i = 0; i < faqs.length; i++) ...[
              if (i != 0) const ThinDivider(indent: AppSpacing.s12),
              EntranceCascadeItem(
                index: i,
                child: SupportFaqRow(faq: faqs[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
