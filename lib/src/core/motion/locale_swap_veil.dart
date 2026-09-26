import 'dart:async';

import 'package:flutter/widgets.dart';

import 'locale_swap_veil_view.dart';
import 'motion.dart';

/// LANGUAGE SWITCH VEIL — changing the app language rebuilds (and mirrors)
/// the whole tree in one frame, which reads as a glitch. [run] fades a solid
/// veil over the app, performs [commit] underneath, then fades it away, so
/// the switch reads as one calm cross-fade instead of two app trees fighting.
/// Never slide or cross-fade the trees themselves. Under reduced motion (or
/// with no overlay) it just commits.
abstract final class LocaleSwapVeil {
  /// Runs [commit] under the veil; completes when the veil is gone. Errors
  /// thrown by [commit] are rethrown after the veil is removed.
  static Future<void> run(
    BuildContext context, {
    required Color color,
    required Future<void> Function() commit,
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null || MotionGuard.reduced(context)) {
      await commit();
      return;
    }
    final done = Completer<Object?>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => LocaleSwapVeilView(
        color: color,
        commit: commit,
        onDone: (error) {
          entry.remove();
          done.complete(error);
        },
      ),
    );
    overlay.insert(entry);
    final error = await done.future;
    if (error != null) throw error;
  }
}
