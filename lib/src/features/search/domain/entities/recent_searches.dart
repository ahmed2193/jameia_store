import 'package:equatable/equatable.dart';

/// The customer's recent search terms, newest first. Owns the rules: a term is
/// trimmed, a repeat (whatever its letter case) moves to the front instead of
/// duplicating, and only the last [maxTerms] are kept.
class RecentSearches extends Equatable {
  const RecentSearches(this.terms);

  static const RecentSearches empty = RecentSearches(<String>[]);
  static const int maxTerms = 10;

  /// How many past terms are offered while the customer types.
  static const int maxMatches = 3;

  final List<String> terms;

  bool get isEmpty => terms.isEmpty;

  /// A new list with [term] first. A blank term changes nothing.
  RecentSearches add(String term) {
    final clean = term.trim();
    if (clean.isEmpty) return this;
    final lower = clean.toLowerCase();
    return RecentSearches(
      [
        clean,
        ...terms.where((existing) => existing.toLowerCase() != lower),
      ].take(maxTerms).toList(growable: false),
    );
  }

  /// The past terms that contain [text] (letter case ignored), newest first
  /// and at most [maxMatches]. The term the customer has typed in full is
  /// left out: "see all results" already searches for it.
  List<String> matching(String text) {
    final needle = text.trim().toLowerCase();
    if (needle.isEmpty) return const <String>[];
    return terms
        .where((term) {
          final lower = term.toLowerCase();
          return lower != needle && lower.contains(needle);
        })
        .take(maxMatches)
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [terms];
}
