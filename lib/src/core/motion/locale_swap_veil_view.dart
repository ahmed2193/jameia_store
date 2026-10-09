import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

/// The overlay [LocaleSwapVeil] shows. With a [snapshot] (the app's last
/// frame) it holds that picture up at once — the customer keeps seeing the
/// screen they tapped on, never an empty one — runs [commit] (the language
/// switch) under it, waits for the new locale's frames, then fades the
/// picture away: the old screen cross-fades into the new language. Without
/// one it fades a [color] veil in first. [onDone] runs even when [commit]
/// throws, so the veil can never stay stuck on screen. The view owns
/// [snapshot] and disposes it.
class LocaleSwapVeilView extends StatefulWidget {
  const LocaleSwapVeilView({
    super.key,
    required this.color,
    this.snapshot,
    required this.commit,
    required this.onDone,
  });

  final Color color;

  /// The app as it was on screen when the switch began.
  final ui.Image? snapshot;

  final Future<void> Function() commit;
  final void Function(Object? error) onDone;

  @override
  State<LocaleSwapVeilView> createState() => _LocaleSwapVeilViewState();
}

class _LocaleSwapVeilViewState extends State<LocaleSwapVeilView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    reverseDuration: AppMotion.medium,
    // The snapshot IS the current frame: up at once, nothing to fade in.
    value: widget.snapshot == null ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    Object? error;
    try {
      if (widget.snapshot == null) await _controller.forward().orCancel;
      await widget.commit();
      // The new locale's first frame, then one more: `Localizations` swaps
      // its resources (and the text direction) a frame after the locale.
      await SchedulerBinding.instance.endOfFrame;
      await SchedulerBinding.instance.endOfFrame;
    } on TickerCanceled {
      // Disposed mid-way: fall through to onDone.
    } on Object catch (e) {
      error = e;
    }
    try {
      if (mounted) await _controller.reverse().orCancel;
    } on TickerCanceled {
      // Disposed while fading out.
    }
    widget.onDone(error);
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    // Taps wait while the veil is up: the tree under it is not the one
    // the customer can see.
    return AbsorbPointer(
      child: FadeTransition(
        opacity: _controller,
        child: snapshot != null
            ? RawImage(image: snapshot, fit: BoxFit.fill)
            : ColoredBox(color: widget.color, child: const SizedBox.expand()),
      ),
    );
  }
}
