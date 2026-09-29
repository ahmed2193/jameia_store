import 'package:flutter/widgets.dart';

import '../motion/motion.dart';
import 'hero_snack_line.dart';
import 'hero_snack_message.dart';

/// The inside of every Hero snack bar (`showHeroSnackBar`). A snack that
/// replaces one still on screen arrives already standing where the old one
/// stood and starts from [previous]: the old words fade out while the new
/// ones fade in over [AppMotion.fast] (docs/motion §9.4 #15 — a replacement
/// cross-fades instead of leaving and coming back). Reduced motion: the new
/// words at once. Only [message] is read out.
class HeroSnackContent extends StatefulWidget {
  const HeroSnackContent({super.key, required this.message, this.previous});

  final HeroSnackMessage message;

  /// What the snack on screen said before this one replaced it.
  final HeroSnackMessage? previous;

  @override
  State<HeroSnackContent> createState() => _HeroSnackContentState();
}

class _HeroSnackContentState extends State<HeroSnackContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );
  late final CurvedAnimation _incoming = CurvedAnimation(
    parent: _swap,
    curve: AppMotion.signature,
  );
  late final CurvedAnimation _leaving = CurvedAnimation(
    parent: _swap,
    curve: AppMotion.exit,
  );
  late final Animation<double> _outgoing = ReverseAnimation(_leaving);
  bool _started = false;
  bool _settled = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final previous = widget.previous;
    if (previous == null ||
        previous == widget.message ||
        MotionGuard.reduced(context)) {
      _swap.value = 1;
      return;
    }
    _settled = false;
    _swap.forward().whenCompleteOrCancel(() {
      if (mounted) setState(() => _settled = true);
    });
  }

  @override
  void dispose() {
    _incoming.dispose();
    _leaving.dispose();
    _swap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = HeroSnackLine(message: widget.message);
    final previous = widget.previous;
    if (_settled || previous == null) return line;
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        ExcludeSemantics(
          child: FadeTransition(
            opacity: _outgoing,
            child: HeroSnackLine(message: previous),
          ),
        ),
        FadeTransition(opacity: _incoming, child: line),
      ],
    );
  }
}
