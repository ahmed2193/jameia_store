import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'cache_object_key_mirror.dart';
import 'image_disk_index.dart';

/// The image store's metadata repository: [JsonCacheInfoRepository] plus
///
///  * [ImageDiskIndex] kept in step with the store's own cleanup
///    (`CacheStore._cleanupCache`, flutter_cache_manager 3.4.3
///    cache_store.dart:145-160, deletes exactly the objects
///    [getObjectsOverCapacity] and [getOldObjects] return, so each of them
///    leaves that index as it is handed over), and
///  * an O(1) key lookup. The base [get] is a `firstWhereOrNull` over every
///    cached object (json_cache_info_repository.dart:48-52), run for each
///    cache read that misses the store's memory cache (~10 000 objects at the
///    configured capacity); a [CacheObjectKeyMirror] answers it instead. The
///    on-disk JSON and every returned value are exactly the base class's.
///
/// The base class keeps its maps, `_readFile` and `_put` private, so the
/// mirror is a copy kept honest three ways:
///  * every base mutation happens synchronously inside the `super` call, so
///    [update], [delete] and [deleteAll] mirror it in the same synchronous
///    step; [update] hands the base an already resolved object so mirror and
///    base hold the same values (`updateOrInsert` dispatches to the
///    overridden [insert] / [update]; `_readFile` only runs inside [open]);
///  * [insert] cannot know the stored object (its id and persist come later),
///    so it only evicts the key; the next [get] misses, asks the base and
///    remembers the answer. [_epoch] is bumped by every mutation, and an
///    answer is remembered only when no mutation happened since it was asked
///    for, so a slow answer never resurrects an object a later delete removed;
///  * a miss is never trusted: it falls through to `super.get`.
/// If two keys ever share one id the mirror switches itself off for good
/// ([_ambiguous]). It is built once per connection cycle: after the first
/// [open] reads the file, dropped when the last connection closes.
class IndexedJsonCacheInfoRepository extends JsonCacheInfoRepository {
  IndexedJsonCacheInfoRepository({super.path, super.databaseName});

  CacheObjectKeyMirror? _mirror;
  Future<void>? _building;
  bool _opened = false;
  bool _ambiguous = false;

  /// Bumped by everything that changes the base class's content.
  int _epoch = 0;

  /// The keys the O(1) lookup holds, or null while none is built (tests and
  /// debugging; read through `HeroImageCacheManager.debugIndexedKeys`).
  Set<String>? get debugIndexedKeys => _mirror?.keys.toSet();

  @override
  Future<bool> open() async {
    // The first connection re-reads the file; what was mirrored predates it.
    if (openConnections == 0) _reset();
    final bool opened = await super.open();
    _opened = true;
    if (_mirror == null) await _ensureIndex();
    return opened;
  }

  @override
  Future<bool> close() {
    // super.close() runs `shouldClose()` synchronously, so the count already
    // says whether this was the last connection.
    final Future<bool> closing = super.close();
    if (openConnections == 0) _reset();
    return closing;
  }

  @override
  Future<CacheObject?> get(String key) async {
    if (!_opened || _ambiguous) return super.get(key);
    if (_mirror == null) await _ensureIndex();
    final CacheObjectKeyMirror? mirror = _mirror;
    if (mirror == null) return super.get(key);
    final CacheObject? hit = mirror[key];
    if (hit != null) return hit;

    // Not mirrored (an insert evicts its key, the mirror was dropped): ask
    // the base class and remember a still-current answer.
    final int epoch = _epoch;
    final CacheObject? found = await super.get(key);
    if (found != null && epoch == _epoch && identical(mirror, _mirror)) {
      _remember(found);
    }
    return found;
  }

  @override
  Future<CacheObject> insert(
    CacheObject cacheObject, {
    bool setTouchedToNow = true,
  }) async {
    final int epoch = ++_epoch;
    _mirror?.unmap(cacheObject.key); // the base replaces what this key held
    final CacheObject stored = await super.insert(
      cacheObject,
      setTouchedToNow: setTouchedToNow,
    );
    if (epoch == _epoch) _remember(stored); // nothing else moved meanwhile
    return stored;
  }

  @override
  Future<int> update(CacheObject cacheObject, {bool setTouchedToNow = true}) {
    if (cacheObject.id == null) {
      return super.update(cacheObject, setTouchedToNow: setTouchedToNow);
    }
    // Exactly what the base `_put` stores: `fromMap(toMap(setTouchedToNow))`.
    // Handing it back with `setTouchedToNow: false` re-encodes the very same
    // map, so the JSON on disk is unchanged and the mirror holds the base's
    // values (touch time included) instead of a second clock reading.
    final CacheObject stored = CacheObject.fromMap(
      cacheObject.toMap(setTouchedToNow: setTouchedToNow),
    );
    _epoch++;
    _remember(stored);
    return super.update(stored, setTouchedToNow: false);
  }

  @override
  Future<int> delete(int id) {
    _epoch++;
    _mirror?.forgetIds(<int>[id]);
    return super.delete(id);
  }

  @override
  Future<int> deleteAll(Iterable<int> ids) {
    final List<int> list = ids.toList(); // read twice: mirror, then base
    _epoch++;
    _mirror?.forgetIds(list);
    return super.deleteAll(list);
  }

  @override
  Future<List<CacheObject>> getObjectsOverCapacity(int capacity) async =>
      _forget(await super.getObjectsOverCapacity(capacity));

  @override
  Future<List<CacheObject>> getOldObjects(Duration maxAge) async =>
      _forget(await super.getOldObjects(maxAge));

  /// The store deletes everything in [doomed] (its `deleteAll` follows), so
  /// it leaves both indexes now. Evicting early is safe: a lookup in the gap
  /// misses, finds the object in the base and re-adds it, and the `deleteAll`
  /// then removes it by id.
  List<CacheObject> _forget(List<CacheObject> doomed) {
    for (final CacheObject o in doomed) {
      ImageDiskIndex.instance.remove(o.key);
      _mirror?.unmap(o.key);
    }
    return doomed;
  }

  Future<void> _ensureIndex() => _building ??= _buildIndex();

  /// Snapshot of the base class's objects. `getAllObjects` copies them
  /// synchronously when called (json_cache_info_repository.dart:55-57); if
  /// anything mutated before the await resumed the copy is stale and the
  /// attempt is dropped (it retries, then leaves the mirror unbuilt: lookups
  /// fall through to the base until the next [get] tries again).
  Future<void> _buildIndex() async {
    try {
      for (
        int attempt = 0;
        attempt < 3 && _opened && !_ambiguous && _mirror == null;
        attempt++
      ) {
        final int epoch = _epoch;
        final List<CacheObject> all = await super.getAllObjects();
        if (epoch != _epoch) continue;
        final CacheObjectKeyMirror? mirror = CacheObjectKeyMirror.of(all);
        if (mirror == null) {
          _disable();
          return;
        }
        _mirror = mirror;
      }
    } finally {
      _building = null;
    }
  }

  /// Makes [o] the mirrored object of its key (a no-op while unbuilt).
  void _remember(CacheObject o) {
    final CacheObjectKeyMirror? mirror = _mirror;
    if (mirror != null && !mirror.remember(o)) _disable();
  }

  /// A new connection cycle: nothing mirrored, nothing trusted.
  void _reset() {
    _epoch++;
    _opened = false;
    _ambiguous = false;
    _mirror = null;
  }

  /// Two keys share one id: a delete by id cannot be mirrored. Stay out.
  void _disable() {
    _epoch++;
    _ambiguous = true;
    _mirror = null;
  }
}
