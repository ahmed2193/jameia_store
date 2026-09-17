import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import 'highlight_text.dart';

/// Jameia `c_search` typing-state suggestions. Rows are ≥51dp with a grey
/// outline magnifier (16dp, 7dp lead / 16dp gap), the suggestion text (16dp,
/// completion bolded), and a hairline divider indented 39dp. The final row is
/// "Search for [query]" which commits the raw query.
class SuggestionList extends StatelessWidget {
  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.query,
    required this.onTap,
  });

  final List<String> suggestions;
  final String query;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final term = query.trim();
    // +1 trailing "Search for <query>" row (shown when a query is present).
    final showSearchFor = term.isNotEmpty;
    final count = suggestions.length + (showSearchFor ? 1 : 0);

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.only(top: 10),
      itemCount: count,
      itemBuilder: (context, i) {
        final isSearchFor = showSearchFor && i == suggestions.length;
        final last = i == count - 1;
        return Column(
          children: [
            PressScale(
              child: InkWell(
                onTap: () => onTap(isSearchFor ? term : suggestions[i]),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 51),
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsetsDirectional.only(start: 7, end: 16),
                  child: Row(
                    children: [
                      const Icon(
                        JameiaIcons.search,
                        size: 16,
                        color: AppColors.tertiaryText,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: isSearchFor
                            ? _SearchForText(query: term)
                            : buildSuggestionText(suggestions[i], term),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!last)
              const Padding(
                padding: EdgeInsetsDirectional.only(start: 39),
                child: ColoredBox(
                  color: AppColors.overlayDivider, // #00000014 (~8% black)
                  child: SizedBox(height: 1, width: double.infinity),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "Search for [query]" — label regular, the quoted query bold.
class _SearchForText extends StatelessWidget {
  const _SearchForText({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.headingMedium.copyWith(
      color: AppColors.black,
      fontWeight: AppTextStyles.regular,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '${'search.search_for'.tr()} '),
          TextSpan(
            text: '"$query"',
            style: base.copyWith(fontWeight: AppTextStyles.bold),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
