import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    show CacheObject;

/// A key → object mirror of a `JsonCacheInfoRepository`'s objects, with the
/// id → key back map its deletes need (the repository deletes by id).
/// `IndexedJsonCacheInfoRepository` keeps it in step with every mutation.
///
/// If two keys ever share one id a delete could not be mirrored: [of] and
/// [remember] report that (null / false) and the owner stops mirroring.
class CacheObjectKeyMirror {
  CacheObjectKeyMirror._(this._byKey, this._keyById);

  /// A mirror of [all] (one object per key, as `getAllObjects` returns
  /// them), or null when two of them share one id.
  static CacheObjectKeyMirror? of(Iterable<CacheObject> all) {
    final Map<String, CacheObject> byKey = <String, CacheObject>{};
    final Map<int, String> keyById = <int, String>{};
    for (final CacheObject o in all) {
      final int? id = o.id;
      if (id != null && keyById.containsKey(id)) return null;
      byKey[o.key] = o;
      if (id != null) keyById[id] = o.key;
    }
    return CacheObjectKeyMirror._(byKey, keyById);
  }

  final Map<String, CacheObject> _byKey;
  final Map<int, String> _keyById;

  /// The mirrored object of [key], if any.
  CacheObject? operator [](String key) => _byKey[key];

  /// Every mirrored key.
  Iterable<String> get keys => _byKey.keys;

  /// Makes [o] the mirrored object of its key (an id-less object is not
  /// mirrored). False when [o]'s id already belongs to another key.
  bool remember(CacheObject o) {
    final int? id = o.id;
    if (id == null) return true;
    final String? owner = _keyById[id];
    if (owner != null && owner != o.key) return false;
    unmap(o.key); // frees the id this key held before
    _byKey[o.key] = o;
    _keyById[id] = o.key;
    return true;
  }

  /// Forgets [key] and the id it held.
  void unmap(String key) {
    final CacheObject? old = _byKey.remove(key);
    final int? id = old?.id;
    if (id != null && _keyById[id] == key) _keyById.remove(id);
  }

  /// Mirrors the repository's own `_removeById`: the object holding each of
  /// [ids] goes.
  void forgetIds(Iterable<int> ids) {
    for (final int id in ids) {
      final String? key = _keyById.remove(id);
      if (key != null && _byKey[key]?.id == id) _byKey.remove(key);
    }
  }
}
