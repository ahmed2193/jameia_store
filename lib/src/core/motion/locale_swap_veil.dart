import 'dart:async';

import 'package:flutter/widgets.dart';

import 'locale_swap_veil_host.dart';
import 'locale_swap_veil_view.dart';
import 'motion.dart';

/// LANGUAGE SWITCH VEIL — changing the app language rebuilds (and mirrors)
/// the whole tree in one frame, which reads as a glitch. [run] fades a solid
/// veil over the app, performs [commit] underneath, then fades it away, so
/// the switch reads as one calm cross-fade instead of two app trees fighting.
/// Never slide or cross-fade the trees themselves.
///
/// The veil goes on the app's [LocaleSwapVeilHost] — over the routes AND the
/// connection banner (docs/motion B3-04) — or, with no host, on the root
/// overlay. Taps wait while it is up. Under reduced motion (or with nowhere
/// to draw it) it just commits.
abstract final class LocaleSwapVeil {
  /// Runs [commit] under the veil; completes when the veil is gone. Errors
  /// thrown by [commit] are rethrown after the veil is removed.
  static Future<void> run(
    BuildContext context, {
    required Color color,
    required Future<void> Function() commit,
  }) async {
    final host = LocaleSwapVeilHost.maybeOf(context);
    final overlay = host == null
        ? Overlay.maybeOf(context, rootOverlay: true)
        : null;
    if ((host == null && overlay == null) || MotionGuard.reduced(context)) {
      await commit();
      return;
    }
    final done = Completer<Object?>();
    if (host != null) {
      late final Widget veil;
      veil = LocaleSwapVeilView(
        color: color,
        commit: commit,
        onDone: (error) {
          host.remove(veil);
          done.complete(error);
        },
      );
      host.show(veil);
    } else {
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
      overlay!.insert(entry);
    }
    final error = await done.future;
    if (error != null) throw error;
  }
}
