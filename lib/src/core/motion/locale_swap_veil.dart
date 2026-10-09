import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'locale_swap_veil_host.dart';
import 'locale_swap_veil_view.dart';
import 'motion.dart';

/// LANGUAGE SWITCH VEIL — changing the app language rebuilds (and mirrors)
/// the whole tree in one frame, which reads as a glitch. [run] holds a
/// picture of the app's last frame over it, performs [commit] underneath,
/// then fades the picture away, so the old screen cross-fades into the new
/// language — never an empty screen, never two live app trees (the old one
/// is one texture). Never slide or cross-fade the trees themselves.
///
/// The veil goes on the app's [LocaleSwapVeilHost] — over the routes AND the
/// connection banner (docs/motion B3-04) — or, with no host, on the root
/// overlay as a solid [color] veil (also the host's fallback when the
/// picture cannot be taken). Taps wait while it is up. Under reduced motion
/// (or with nowhere to draw it) it just commits.
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
      // Taken right after a frame is painted, so the picture is exactly
      // what the customer sees.
      await SchedulerBinding.instance.endOfFrame;
      if (!host.mounted) {
        await commit();
        return;
      }
      final snapshot = host.snapshot();
      late final Widget veil;
      veil = LocaleSwapVeilView(
        color: color,
        snapshot: snapshot,
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
