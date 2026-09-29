import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';

/// The overlay [LocaleSwapVeil] shows: fades a [color] veil in, runs
/// [commit] (the language switch) under it, waits one frame for the new
/// locale to lay out, fades the veil out, then calls [onDone]. [onDone] runs
/// even when [commit] throws, so the veil can never stay stuck on screen.
class LocaleSwapVeilView extends StatefulWidget {
  const LocaleSwapVeilView({
    super.key,
    required this.color,
    required this.commit,
    required this.onDone,
  });

  final Color color;
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
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    Object? error;
    try {
      await _controller.forward().orCancel;
      await widget.commit();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Taps wait while the veil is up: the tree under it is not the one
    // the customer can see.
    return AbsorbPointer(
      child: FadeTransition(
        opacity: _controller,
        child: ColoredBox(color: widget.color, child: const SizedBox.expand()),
      ),
    );
  }
}
