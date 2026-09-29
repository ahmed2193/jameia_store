import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/rotating_line.dart';
import 'home_search_hint_typing.dart';

/// The search pill's hint, suggesting what to look for: "Search products",
/// then "Search for "milk"", "Search for "bread""… on the app's one ticker
/// ([RotatingLine]: one every `AppMotion.carousel`, each rising into place
/// as the last leaves above), each suggestion typing itself in behind a
/// caret ([HomeSearchHintTyping]).
///
/// Rotating is ambient motion: the plain hint stays under reduced motion,
/// with a screen reader on (the pill's own label never changes), while its
/// tab is behind another, off screen or in the background, and the line
/// rolls for at most the ambient budget each time it comes into view.
class HomeSearchHint extends StatelessWidget {
  const HomeSearchHint({super.key, required this.style});

  final TextStyle style;

  static const String _listSeparator = ',';

  /// The store's suggestions, in the reader's language.
  static List<String> get _suggestions => [
    for (final item in 'home.search_suggestions'.tr().split(_listSeparator))
      if (item.trim().isNotEmpty) item.trim(),
  ];

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    // Ids by place, so a language switch changes the words in place.
    return RotatingLine(
      items: [
        RotatingLineItem(
          id: 0,
          child: Text(
            'home.search_products'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        for (var i = 0; i < suggestions.length; i++)
          RotatingLineItem(
            id: i + 1,
            child: HomeSearchHintTyping(item: suggestions[i], style: style),
          ),
      ],
    );
  }
}
