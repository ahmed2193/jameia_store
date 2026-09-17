import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

/// Jameia search-suggestion emphasis: the typed prefix (up to and including the
/// matched query) stays regular, and the COMPLETION (everything after) is bold —
/// e.g. typing "McDon" renders `McDon` regular + `ald's` bold. Falls back to all
/// regular when the query isn't found. Text is 16dp #000 per the c_search bundle.
Widget buildSuggestionText(String text, String query) {
  final base = AppTextStyles.headingMedium.copyWith(
    color: AppColors.black,
    fontWeight: AppTextStyles.regular,
  );
  final bold = base.copyWith(fontWeight: AppTextStyles.bold);
  final q = query.trim();
  final idx = q.isEmpty ? -1 : text.toLowerCase().indexOf(q.toLowerCase());
  if (idx < 0) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
  }
  final matchEnd = idx + q.length;
  final head = text.substring(0, matchEnd); // prefix + matched query
  final tail = text.substring(matchEnd); // completion
  return Text.rich(
    TextSpan(
      style: base,
      children: [
        TextSpan(text: head),
        if (tail.isNotEmpty) TextSpan(text: tail, style: bold),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}
