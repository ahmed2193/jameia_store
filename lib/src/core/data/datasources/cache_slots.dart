import '../../network/locale_provider.dart';
import '../../storage/cache_key.dart';
import '../../storage/cache_namespace.dart';
import '../../storage/cache_owner.dart';
import '../../storage/json_cache_store.dart';

/// One cached response, bound to its key when a load STARTS — the language
/// and the identity are captured then, so a reply is saved under the
/// language it was fetched in. A cache datasource hands it to its
/// repository; the policy (fresh / stale / too old, what to do with a copy
/// that no longer parses, a reply for a signed-out owner) lives in
/// `CachedRepositoryMixin`.
abstract class CacheSlot<M> {
  CacheNamespace get namespace;

  /// The saved copy (raw), or `null`.
  Future<CachedJson?> read();

  /// Re-parses a saved copy with the DTO's own `fromJson`; throws when the
  /// shape no longer parses.
  M parse(Object raw);

  Future<void> write(Object raw, {required DateTime savedAt});

  Future<void> remove();

  /// The identity this slot was taken for is still the app's current one.
  bool get isCurrent;
}

/// Builds [CacheSlot]s for the current language and identity. Every cache
/// datasource holds one; `null` means "do not cache now" — the identity a
/// personal namespace needs is not known (launch, before the session
/// restore), or there is no customer for a customer-only namespace.
class CacheSlots {
  const CacheSlots({
    required this._store,
    required this._owner,
    required this._locale,
  });

  final JsonCacheStore _store;
  final CacheOwner _owner;
  final LocaleProvider _locale;

  /// Forgets every saved copy of [namespace] (see
  /// [JsonCacheStore.removeNamespace]).
  Future<void> forget(CacheNamespace namespace) =>
      _store.removeNamespace(namespace);

  CacheSlot<M>? of<M>(
    CacheNamespace namespace, {
    required M Function(Object raw) parse,
    String id = '',
  }) {
    final owner = switch (namespace.scope) {
      CacheScope.public => CacheKey.publicOwner,
      CacheScope.owner => _owner.current,
      CacheScope.customer => _owner.customer,
    };
    if (owner == null) return null;
    return _JsonCacheSlot<M>(
      _store,
      _owner,
      CacheKey(
        namespace: namespace,
        language: _locale.languageCode,
        owner: owner,
        id: id,
      ),
      parse,
    );
  }
}

class _JsonCacheSlot<M> implements CacheSlot<M> {
  _JsonCacheSlot(this._store, this._owner, this._key, this._parse);

  final JsonCacheStore _store;
  final CacheOwner _owner;
  final CacheKey _key;
  final M Function(Object raw) _parse;

  @override
  CacheNamespace get namespace => _key.namespace;

  @override
  Future<CachedJson?> read() => _store.read(_key);

  @override
  M parse(Object raw) => _parse(raw);

  @override
  Future<void> write(Object raw, {required DateTime savedAt}) =>
      _store.write(_key, raw, savedAt: savedAt);

  @override
  Future<void> remove() => _store.remove(_key);

  @override
  bool get isCurrent =>
      _key.owner == CacheKey.publicOwner || _key.owner == _owner.current;
}
