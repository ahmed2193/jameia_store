import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/hero_section_header.dart';
import 'search_term_chip.dart';

/// "Recent searches" with its "Clear" link, then the terms as outlined pill
/// chips, newest first. A chip searches for its term again.
class SearchRecentsSection extends StatelessWidget {
  const SearchRecentsSection({
    super.key,
    required this.terms,
    required this.onTerm,
    required this.onClear,
  });

  final List<String> terms;
  final ValueChanged<String> onTerm;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HeroSectionHeader(
          title: 'search.recent'.tr(),
          onSeeAll: onClear,
          seeAllLabel: 'search.clear_recent'.tr(),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.gutter,
          ),
          child: Wrap(
            spacing: AppSpacing.s8,
            children: [
              for (final term in terms)
                SearchTermChip(
                  key: ValueKey<String>(term),
                  label: term,
                  icon: Icons.history_rounded,
                  onTap: () => onTerm(term),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
