import 'package:flutter/material.dart';

import '../../../../config/theme/app_text_styles.dart';

/// [text] with the first case-insensitive occurrence of [query] in bold — how
/// a suggestion shows what matched (weight, not colour, carries it).
class SearchHighlightedText extends StatelessWidget {
  const SearchHighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.maxLines = 2,
  });

  final String text;
  final String query;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.itemTitle;
    final needle = query.trim().toLowerCase();
    final start = needle.isEmpty ? -1 : text.toLowerCase().indexOf(needle);
    if (start < 0) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }
    final end = start + needle.length;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: base.copyWith(fontWeight: AppTextStyles.bold),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
