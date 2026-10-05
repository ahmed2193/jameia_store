import 'package:flutter/widgets.dart';

import '../domain/localization/text_direction_estimate.dart';

/// The direction a field's text reads in, following what is typed — an
/// English street typed in the Arabic app reads left to right — while the
/// field stays aligned to the layout's start side: `HeroBidiText`'s rule,
/// for an input. Listen to it and rebuild only the input when it flips.
class TypedTextDirection extends ValueNotifier<bool?> {
  /// Seeded from the field's first [text].
  TypedTextDirection([String text = ''])
    : super(TextDirectionEstimate.isRtl(text));

  /// [text] is in the field now.
  void follow(String text) => value = TextDirectionEstimate.isRtl(text);

  /// The input's direction under [layout] (the layout's own while the text
  /// has no letter).
  TextDirection directionIn(TextDirection layout) => switch (value) {
    true => TextDirection.rtl,
    false => TextDirection.ltr,
    null => layout,
  };

  /// The layout's start side, whatever the text's direction.
  static TextAlign startOf(TextDirection layout) =>
      layout == TextDirection.rtl ? TextAlign.right : TextAlign.left;
}
