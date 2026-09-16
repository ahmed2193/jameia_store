import 'dart:convert';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/storage/local_storage.dart';

/// Offline source for the global search feature. The live KeeTa page hits
/// `/api/search/*` + a server-side recents store; here matches come from the
/// in-memory [KeetaRepository] catalogue and the recents list is persisted to
/// [LocalStorage] (shared_preferences) so it survives app restarts.
abstract class SearchLocalDataSource {
  /// Catalogue shops matching [query] (delegates to [KeetaRepository.searchShops]).
  List<Shop> searchShops(String query);

  /// Popular-brands strip for the discover landing — catalogue shops that have a
  /// logo, capped at the first 16 (mirrors KeeTa's `popular brands` block).
  List<Shop> popularBrands();

  /// Type-ahead completions for [query] — a small deduped mix of matching
  /// product + shop + category names (prefix matches first), cap 8.
  List<String> suggestions(String query);

  /// Hot-word chips derived from the most common shop tags (dedup, cap 10).
  List<String> hotWords();

  /// The persisted recent searches (most-recent first); empty when none / on
  /// decode error.
  List<String> recentSearches();

  /// Overwrite the persisted recents with [terms].
  Future<void> saveRecentSearches(List<String> terms);
}

class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  SearchLocalDataSourceImpl(this.catalog, this.storage);

  final KeetaRepository catalog;
  final LocalStorage storage;

  /// Namespaced recents key — versioned so a schema bump is a one-line change.
  static const String _recentsKey = 'keeta.search.recents.v1';

  /// Max type-ahead completions.
  static const int _maxSuggestions = 8;

  @override
  List<Shop> searchShops(String query) => catalog.searchShops(query);

  @override
  List<Shop> popularBrands() => catalog.shops
      .where((s) => s.logo.isNotEmpty)
      .take(16)
      .toList(growable: false);

  @override
  List<String> suggestions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    // Rank prefix matches ahead of mid-string matches, dedup case-insensitively.
    final prefix = <String>[];
    final contains = <String>[];
    final seen = <String>{};

    void offer(String raw) {
      final name = raw.trim();
      if (name.isEmpty) return;
      final lower = name.toLowerCase();
      if (!lower.contains(q) || !seen.add(lower)) return;
      (lower.startsWith(q) ? prefix : contains).add(name);
    }

    for (final c in catalog.categories) {
      offer(c.displayName);
    }
    for (final s in catalog.shops) {
      offer(s.displayName);
    }
    for (final p in catalog.allProducts) {
      if (prefix.length + contains.length >= _maxSuggestions * 4) break;
      offer(p.displayName);
    }
    return [...prefix, ...contains].take(_maxSuggestions).toList(growable: false);
  }

  @override
  List<String> hotWords() {
    // Derived from the most common shop tags in the catalog, mirroring KeeTa's
    // server-driven `hotword` block. Cap at the first 10 distinct tags.
    final seen = <String>{};
    final words = <String>[];
    for (final s in catalog.shops) {
      for (final t in s.tags) {
        if (seen.add(t)) words.add(t);
        if (words.length >= 10) return words;
      }
    }
    return words;
  }

  @override
  List<String> recentSearches() {
    final raw = storage.getString(_recentsKey);
    if (raw == null) return const [];
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
      return const [];
    } catch (_) {
      return const []; // corrupt payload → treat as no history
    }
  }

  @override
  Future<void> saveRecentSearches(List<String> terms) =>
      storage.setString(_recentsKey, json.encode(terms));
}
