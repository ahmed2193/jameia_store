import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';

/// Recent search terms on the device (newest first), a JSON string list.
abstract class SearchLocalDataSource {
  List<String> readRecentSearches();

  Future<void> writeRecentSearches(List<String> terms);
}

class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  const SearchLocalDataSourceImpl(this._storage);

  final LocalStorage _storage;

  /// Unchanged since the offline search: the customer keeps their history.
  static const String recentsKey = 'jameia.search.recents.v1';

  @override
  List<String> readRecentSearches() {
    final raw = _storage.getString(recentsKey);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return [
        for (final term in decoded)
          if (term is String && term.isNotEmpty) term,
      ];
    } on FormatException {
      // A corrupt value is an empty history, never a broken search screen.
      return const <String>[];
    }
  }

  @override
  Future<void> writeRecentSearches(List<String> terms) async {
    final saved = terms.isEmpty
        ? await _storage.remove(recentsKey)
        : await _storage.setString(recentsKey, jsonEncode(terms));
    // `remove` answers false when there was nothing to remove: not a failure.
    if (!saved && terms.isNotEmpty) {
      throw const CacheException('search: recent terms not saved');
    }
  }
}
