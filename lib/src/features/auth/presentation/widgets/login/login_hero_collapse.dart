import 'package:flutter/widgets.dart';

import '../../../../../core/motion/motion.dart';

/// Folds [child] away while the keyboard is up, so the phone field and the
/// CTA stay in view on a short phone, and unfolds it when the keyboard goes.
///
/// It watches the window's own keyboard inset (the Scaffold strips the
/// inset from its body's `MediaQuery` once it has resized for it) through
/// the metrics callback, and only reacts when "keyboard up" flips — nothing
/// rebuilds while the keyboard slides. Reduced motion → an instant cut.
class LoginHeroCollapse extends StatefulWidget {
  const LoginHeroCollapse({super.key, required this.child});

  final Widget child;

  @override
  State<LoginHeroCollapse> createState() => _LoginHeroCollapseState();
}

class _LoginHeroCollapseState extends State<LoginHeroCollapse>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _open,
    curve: AppMotion.signature,
  );
  bool? _keyboardUp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeMetrics() => _sync();

  void _sync() {
    if (!mounted) return;
    final keyboardUp = View.of(context).viewInsets.bottom > 0;
    if (keyboardUp == _keyboardUp) return;
    final firstLayout = _keyboardUp == null;
    _keyboardUp = keyboardUp;
    final target = keyboardUp ? 0.0 : 1.0;
    if (firstLayout || MotionGuard.reduced(context)) {
      _open.value = target;
    } else {
      _open.animateTo(target);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _curve.dispose();
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SizeTransition(
        sizeFactor: _curve,
        alignment: AlignmentDirectional.topCenter,
        child: widget.child,
      ),
    );
  }
}
