import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../domain/entities/place_suggestion.dart';
import '../../../domain/entities/text_match.dart';
import 'address_search_row.dart';
import 'place_suggestion_text.dart';
import 'suggestion_fill_button.dart';
import 'suggestion_leading.dart';

/// One answer of the address search, Google Maps style: a pin on a grey
/// disc with how far the place is under it, the name with the typed words
/// in bold over where it is ([suggestionLine]), and — given [onFill] — the
/// ↖ that puts the name in the search box. While its point is looked up the
/// dots stand at the row's end and the row takes no tap.
class PlaceSuggestionRow extends StatelessWidget {
  const PlaceSuggestionRow({
    super.key,
    required this.suggestion,
    required this.lookingUp,
    required this.onTap,
    this.onFill,
  });

  final PlaceSuggestion suggestion;
  final bool lookingUp;
  final VoidCallback? onTap;
  final VoidCallback? onFill;

  static const double _metersPerKm = 1000;

  /// [title] cut into plain and bold stretches
  /// ([TextMatch.boldStretchesIn]).
  static List<TextSpan> _spans(String title, List<TextMatch> matches) {
    final spans = <TextSpan>[];
    var at = 0;
    for (final match in TextMatch.boldStretchesIn(title, matches)) {
      if (match.start > at) {
        spans.add(TextSpan(text: title.substring(at, match.start)));
      }
      spans.add(
        TextSpan(
          text: title.substring(match.start, match.end),
          style: const TextStyle(fontWeight: AppTextStyles.bold),
        ),
      );
      at = match.end;
    }
    if (at < title.length) spans.add(TextSpan(text: title.substring(at)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final meters = suggestion.distanceMeters;
    final line = suggestionLine(
      suggestion,
      rtl: Directionality.of(context) == TextDirection.rtl,
    );
    final onFill = this.onFill;
    return AddressSearchRow(
      onTap: lookingUp ? null : onTap,
      trailingButton: onFill != null,
      leading: SuggestionLeading(
        icon: HeroIcons.pin,
        distance: meters == null
            ? null
            : Formatters.distance(meters / _metersPerKm),
      ),
      title: Text.rich(
        TextSpan(children: _spans(suggestion.title, suggestion.titleMatches)),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.itemTitle,
      ),
      subtitle: line.isEmpty
          ? null
          : Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.meta,
            ),
      trailing: onFill != null
          ? SuggestionFillButton(
              label: 'addr.search.fill_in'.tr(args: [suggestion.title]),
              busy: lookingUp,
              onTap: onFill,
            )
          : lookingUp
          ? const AppLoader.inline(size: AppSize.s20)
          : null,
    );
  }
}
