import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../domain/entities/faq_item.dart';
import 'support_faq_tile.dart';
import 'support_no_results.dart';
import 'support_still_need_help_card.dart';

/// The FAQ accordion filtered by [query] (question or answer text), then the
/// "Still need help?" card; the empty state when nothing matches.
class SupportFaqResults extends StatelessWidget {
  const SupportFaqResults({
    super.key,
    required this.faqs,
    required this.query,
    required this.expanded,
  });

  final List<FaqItem> faqs;
  final ValueNotifier<String> query;
  final ValueNotifier<int> expanded;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: query,
      builder: (context, text, _) {
        // Keep the full-list indices so [expanded] stays valid while filtered.
        final matches = <int>[
          for (var i = 0; i < faqs.length; i++)
            if (FaqItem.textMatches(
              text,
              question: faqs[i].questionKey.tr(),
              answer: faqs[i].answerKey.tr(),
            ))
              i,
        ];
        if (matches.isEmpty) return const SupportNoResults();

        // +1 trailing row for the "Still need help?" card.
        return ListView.builder(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.s24,
            start: AppSpacing.s12,
            end: AppSpacing.s12,
          ),
          itemCount: matches.length + 1,
          itemBuilder: (context, row) {
            if (row == matches.length) return const SupportStillNeedHelpCard();
            final fullIndex = matches[row];
            return RepaintBoundary(
              // Keyed by topic so a freshly filtered list cascades in once per
              // item without replaying on expand / collapse rebuilds.
              key: ValueKey<String>(faqs[fullIndex].questionKey),
              child: StaggerEntrance(
                index: row,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: AppSpacing.s8,
                  ),
                  child: SupportFaqTile(
                    index: fullIndex,
                    faq: faqs[fullIndex],
                    expanded: expanded,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
