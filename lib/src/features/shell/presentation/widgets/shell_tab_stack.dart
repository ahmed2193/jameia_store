import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion.dart';

/// The shell's tab bodies (docs/motion §9.4 #9): an [IndexedStack], so every
/// tab keeps its scroll and state, where the tab coming on screen fades in
/// over [AppMotion.fast] (the one leaving cuts). Every hidden tab sits under
/// `TickerMode(enabled: false)` — [IndexedStack] alone keeps them ticking —
/// so nothing animates off screen. No haptic: a tab switch is navigation.
/// Instant under reduced motion.
class ShellTabStack extends StatefulWidget {
  const ShellTabStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<ShellTabStack> createState() => _ShellTabStackState();
}

class _ShellTabStackState extends State<ShellTabStack>
    with SingleTickerProviderStateMixin {
  /// Starts at rest: the first tab is simply there.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
    value: 1,
  );
  late final CurvedAnimation _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.signature,
  );

  @override
  void didUpdateWidget(ShellTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    if (MotionGuard.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = widget.children;
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < children.length; i++)
          TickerMode(
            enabled: i == widget.index,
            child: FadeTransition(
              opacity: i == widget.index ? _fadeIn : kAlwaysCompleteAnimation,
              child: children[i],
            ),
          ),
      ],
    );
  }
}
