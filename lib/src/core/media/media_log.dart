import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show visibleForTesting;

/// The image pipeline's log lines, on `dart:developer` [developer.log] under
/// a [name]: the VM's Logging stream (DevTools, `vm_log_tail.dart`, which
/// prints `[name] text`). The names below keep the reference app's line
/// formats (`[IMGCACHE] build …`, `[ImageCacheTuner] pressure → …`,
/// `[ImageDiskIndex] seeded N of M`), so its trace scripts parse ours.
///
/// Callers gate their own lines (`kDebugMode`, `ImageLoadTrace.enabled`);
/// errors are logged in every build mode, as before.
abstract final class MediaLog {
  /// The debug load trace (`ImageLoadTrace`) and prefetch summaries.
  static const String trace = 'IMGCACHE';

  /// The RAM budget and memory-pressure trims (`ImageCacheTuner`,
  /// `TrimmingImageCache`).
  static const String tuner = 'ImageCacheTuner';

  /// The disk-known index (`ImageDiskIndex`).
  static const String diskIndex = 'ImageDiskIndex';

  /// The disk cache (`HeroImageCacheManager`): clear / remove errors.
  static const String cache = 'HeroImageCache';

  /// The debug byte audit (`ImageBytesTracker`).
  static const String bytes = 'ImageBytes';

  /// View-model / cubit lifecycle lines on the trace switch.
  static const String vmLife = 'VMLIFE';

  /// Test seam: while set, every line goes here instead of the VM log.
  @visibleForTesting
  static void Function(String name, String message)? debugSink;

  /// Logs [message] under [name].
  static void line(String name, String message) {
    final void Function(String, String)? sink = debugSink;
    if (sink != null) {
      sink(name, message);
    } else {
      developer.log(message, name: name);
    }
  }

  /// A line as `vm_log_tail.dart` prints it: `[name] message`.
  static String format(String name, String message) => '[$name] $message';
}
