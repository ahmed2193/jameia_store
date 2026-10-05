import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/localization/localized_pick.dart';

/// A district of Kuwait the app knows without the network: its names in
/// both languages, its governorate and roughly where its middle is. The
/// place search finds it by name however the name is typed.
class KnownArea extends Equatable {
  const KnownArea({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.location,
    this.governorateEn = '',
    this.governorateAr = '',
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final GeoPointEntity location;

  /// The governorate it lies in ("Hawalli Governorate"): the line under its
  /// name in the search.
  final String governorateEn;
  final String governorateAr;

  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: nameEn, ar: nameAr);

  String governorateFor(String languageCode) =>
      pickLocalized(languageCode, en: governorateEn, ar: governorateAr);

  /// Its name in [languageCode] as an A-to-Z list sorts it: the article
  /// set aside, so "Al-Adan" sits among the A's and "العدان" among the ع's.
  String sortKeyFor(String languageCode) => _fold(nameFor(languageCode));

  /// Whether the name, in either language, holds what was [typed]:
  /// "sabah al salem", "Sabah Al-Salem" and "صباح السالم" find the same
  /// district.
  bool matches(String typed) {
    final words = _fold(typed);
    if (words.isEmpty) return false;
    if (_fold(nameEn).contains(words) || _fold(nameAr).contains(words)) {
      return true;
    }
    // Half an article typed ("sabah al", "صباح ا"): the names as written.
    final letters = _squash(typed);
    return _squash(nameEn).contains(letters) ||
        _squash(nameAr).contains(letters);
  }

  /// Whether [typed] is the district's name in full.
  bool isNamedBy(String typed) {
    final words = _fold(typed);
    return words.isNotEmpty &&
        (_fold(nameEn) == words || _fold(nameAr) == words);
  }

  /// A name folded for matching: lower case, the article dropped ("al-",
  /// "al ", a glued "al" as in "Alsalem", "ال"), no spaces, dashes or
  /// apostrophes, Arabic letter forms joined (أ إ آ → ا, ة → ه, ى → ي).
  static String _fold(String text) => _squash(
    text
        .toLowerCase()
        .replaceAll(_latinArticle, '')
        .replaceAll(_arabicArticle, ''),
  );

  /// [text] in lower case without spaces, dashes or apostrophes, Arabic
  /// letter forms joined — the article kept.
  static String _squash(String text) => text
      .toLowerCase()
      .replaceAll(_separators, '')
      .replaceAll(_alefForms, 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');

  static final RegExp _latinArticle = RegExp(r'\bal(?:[\s\-]+|(?=[a-z]{3}))');
  static final RegExp _arabicArticle = RegExp(r'(^|\s)ال');
  static final RegExp _separators = RegExp(r"[\s\-'’]");
  static final RegExp _alefForms = RegExp('[أإآ]');

  @override
  List<Object?> get props => [
    id,
    nameEn,
    nameAr,
    location,
    governorateEn,
    governorateAr,
  ];
}
