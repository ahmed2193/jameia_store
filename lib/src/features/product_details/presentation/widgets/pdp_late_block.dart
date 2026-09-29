import 'package:flutter/widgets.dart';

import '../../../../core/motion/collapse_reveal.dart';
import '../../../../core/motion/motion.dart';

/// One block of the product page. A block that was there when the page
/// first showed is simply there (the page's cascade brings it in); one that
/// arrives LATER — a rail or the recipes landing with the server's copy
/// after the saved one — opens its room (height + fade, [CollapseReveal])
/// instead of popping in and shoving the blocks below down. [late] is read
/// once, when the block mounts. Reduced motion → it is simply there.
class PdpLateBlock extends StatefulWidget {
  const PdpLateBlock({super.key, required this.late, required this.child});

  final bool late;
  final Widget child;

  @override
  State<PdpLateBlock> createState() => _PdpLateBlockState();
}

class _PdpLateBlockState extends State<PdpLateBlock> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = !widget.late;
    if (_open) return;
    // Mounted closed, opened on the next frame: the reveal runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _open = true);
    });
  }

  @override
  Widget build(BuildContext context) => CollapseReveal(
    visible: _open || MotionGuard.reduced(context),
    child: widget.child,
  );
}
