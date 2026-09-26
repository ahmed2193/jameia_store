import 'package:flutter/widgets.dart';

import 'haptics.dart';
import 'shake_x.dart';

/// Lets a disabled CTA say "no": a tap while [blocked] shakes it ([ShakeX])
/// and fires [HapticKind.warning]. The page already shows why (a reason line)
/// — this points at it. Not blocked → a plain pass-through. The disabled
/// button has no tap handler of its own, so this outer detector wins the
/// gesture arena. Pass `blocked: <disabled for a stated reason> && !loading`.
class BlockedTapShake extends StatefulWidget {
  const BlockedTapShake({
    super.key,
    required this.blocked,
    required this.child,
  });

  final bool blocked;
  final Widget child;

  @override
  State<BlockedTapShake> createState() => _BlockedTapShakeState();
}

class _BlockedTapShakeState extends State<BlockedTapShake> {
  int _refusals = 0;

  void _refuse() {
    Haptics.warning();
    setState(() => _refusals++);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.blocked ? _refuse : null,
    // The button's own "disabled" state stays what a screen reader hears.
    excludeFromSemantics: true,
    child: ShakeX(shakeKey: _refusals, child: widget.child),
  );
}
