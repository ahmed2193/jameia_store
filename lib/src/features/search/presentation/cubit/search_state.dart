import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recent_searches.dart';
import '../../domain/entities/search_discover.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.recents = RecentSearches.empty,
    this.discover = SearchDiscover.empty,
    this.suggestions = const <CatalogProductEntity>[],
    this.isSuggesting = false,
    this.suggestFailure,
    this.isDiscoverLoading = false,
    this.discoverFailure,
  });

  /// What is in the field right now.
  final String query;
  final RecentSearches recents;
  final SearchDiscover discover;

  /// Product matches for [query] (empty while it is too short).
  final List<CatalogProductEntity> suggestions;

  /// A suggestions request for the current [query] is pending.
  final bool isSuggesting;

  /// Why the suggestions for the current [query] could not load; cleared by
  /// the next keystroke. A `NetworkFailure` turns the list into the offline
  /// one (recent terms + "search needs a connection").
  final Failure? suggestFailure;

  /// The discover blocks' read is running with nothing of theirs on screen
  /// yet: their skeleton shows.
  final bool isDiscoverLoading;

  /// Why the discover blocks could not load when neither has anything to
  /// show (both failed, nothing saved); `null` otherwise.
  final Failure? discoverFailure;

  bool get isTyping => query.trim().isNotEmpty;

  /// Past terms that match what is typed, offered above the products.
  List<String> get recentMatches => recents.matching(query);

  /// Offline, the past terms that match what is typed — or, when none does,
  /// every past term: something to tap instead of an empty list.
  List<String> get offlineTerms {
    final matches = recentMatches;
    return matches.isNotEmpty ? matches : recents.terms;
  }

  /// Nothing to list yet: the first product request for this text is still
  /// running (later keystrokes keep the previous matches on screen).
  bool get isAwaitingSuggestions => isSuggesting && suggestions.isEmpty;

  /// The list while typing is the offline one — the recent terms and "search
  /// needs a connection", no bone rows, no spinner: the request failed for
  /// want of a connection, or the app is [offline] with nothing to show.
  bool showsOfflineList({required bool offline}) =>
      suggestFailure is NetworkFailure || (offline && suggestions.isEmpty);

  SearchState copyWith({
    String? query,
    RecentSearches? recents,
    SearchDiscover? discover,
    List<CatalogProductEntity>? suggestions,
    bool? isSuggesting,
    Failure? suggestFailure,
    bool clearSuggestFailure = false,
    bool? isDiscoverLoading,
    Failure? discoverFailure,
    bool clearDiscoverFailure = false,
  }) => SearchState(
    query: query ?? this.query,
    recents: recents ?? this.recents,
    discover: discover ?? this.discover,
    suggestions: suggestions ?? this.suggestions,
    isSuggesting: isSuggesting ?? this.isSuggesting,
    suggestFailure: clearSuggestFailure
        ? null
        : (suggestFailure ?? this.suggestFailure),
    isDiscoverLoading: isDiscoverLoading ?? this.isDiscoverLoading,
    discoverFailure: clearDiscoverFailure
        ? null
        : (discoverFailure ?? this.discoverFailure),
  );

  @override
  List<Object?> get props => [
    query,
    recents,
    discover,
    suggestions,
    isSuggesting,
    suggestFailure,
    isDiscoverLoading,
    discoverFailure,
  ];
}
