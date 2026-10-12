import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'trimming_image_cache.dart';

/// The app's binding: [WidgetsFlutterBinding] with a [TrimmingImageCache],
/// so OS memory pressure trims the image cache instead of emptying it (the
/// "custom binding overriding createImageCache" pattern documented on
/// [ImageCache]). `main()` calls [ensureInitialized] instead of
/// `WidgetsFlutterBinding.ensureInitialized()`.
class HeroWidgetsBinding extends WidgetsFlutterBinding {
  HeroWidgetsBinding._();

  static bool _created = false;

  // The cache [createImageCache] built; null until the painting binding
  // initialises (see [handleAppLifecycleStateChanged]).
  TrimmingImageCache? _trimmingCache;

  @override
  ImageCache createImageCache() => _trimmingCache = TrimmingImageCache();

  /// Lets the image cache drop a memory-pressure trim still waiting out its
  /// settle window the moment the app leaves the foreground: a HOME press can
  /// deliver its UI_HIDDEN pressure before the `hidden` lifecycle message
  /// (TrimmingImageCache.clear). Null-aware on purpose: the services binding
  /// replays the initial lifecycle state BEFORE the painting binding creates
  /// the cache, and `imageCache` is a `late` field until then.
  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    super.handleAppLifecycleStateChanged(state);
    _trimmingCache?.handleLifecycle(state);
  }

  /// Hot reload with changed assets (`ext.flutter.evict`) must still drop
  /// every decoded image: wipe first, so the framework's own `clear()` here
  /// finds nothing to trim, then let it clear the live images.
  @override
  void evict(String asset) {
    final ImageCache cache = imageCache;
    if (cache is TrimmingImageCache) cache.clearAll();
    super.evict(asset);
  }

  /// Creates the binding once, unless one already exists (a test binding);
  /// returns the active [WidgetsBinding]. `debugBindingType()` is null in
  /// release, where nothing creates a binding before `main()` reaches this.
  static WidgetsBinding ensureInitialized() {
    if (!_created && BindingBase.debugBindingType() == null) {
      _created = true;
      HeroWidgetsBinding._();
    }
    return WidgetsBinding.instance;
  }
}
