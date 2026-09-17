import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// One benefit in the home sticky benefits bar (icon + coloured label).
///
/// [text] holds the Arabic / default copy, [textEn] the English counterpart.
class BenefitItemEntity extends Equatable {
  const BenefitItemEntity({
    required this.text,
    this.textEn = '',
    this.icon = 'bolt',
    this.color = '#F0390E',
  });

  /// Arabic / default text.
  final String text;

  /// English text.
  final String textEn;

  /// Material icon name (mapped in the widget).
  final String icon;

  /// Hex colour.
  final String color;

  /// Active-locale text: [text] when `ar*` and non-blank, else [textEn].
  String textFor(String languageCode) =>
      pickLocalized(languageCode, en: textEn, ar: text);

  @override
  List<Object?> get props => [text, textEn, icon, color];
}
