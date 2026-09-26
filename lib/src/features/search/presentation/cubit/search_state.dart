import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../domain/entities/recent_searches.dart';
import '../../domain/entities/search_discover.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.recents = RecentSearches.empty,
    this.discover = SearchDiscover.empty,
    this.suggestions = const <CatalogProductEntity>[],
    this.isSuggesting = false,
  });

  /// What is in the field right now.
  final String query;
  final RecentSearches recents;
  final SearchDiscover discover;

  /// Product matches for [query] (empty while it is too short).
  final List<CatalogProductEntity> suggestions;

  /// A suggestions request for the current [query] is pending.
  final bool isSuggesting;

  bool get isTyping => query.trim().isNotEmpty;

  /// Past terms that match what is typed, offered above the products.
  List<String> get recentMatches => recents.matching(query);

  /// Nothing to list yet: the first product request for this text is still
  /// running (later keystrokes keep the previous matches on screen).
  bool get isAwaitingSuggestions => isSuggesting && suggestions.isEmpty;

  SearchState copyWith({
    String? query,
    RecentSearches? recents,
    SearchDiscover? discover,
    List<CatalogProductEntity>? suggestions,
    bool? isSuggesting,
  }) => SearchState(
    query: query ?? this.query,
    recents: recents ?? this.recents,
    discover: discover ?? this.discover,
    suggestions: suggestions ?? this.suggestions,
    isSuggesting: isSuggesting ?? this.isSuggesting,
  );

  @override
  List<Object?> get props => [
    query,
    recents,
    discover,
    suggestions,
    isSuggesting,
  ];
}
