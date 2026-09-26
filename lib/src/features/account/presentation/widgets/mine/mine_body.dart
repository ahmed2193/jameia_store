import 'package:flutter/material.dart';

import 'mine_content.dart';

/// The Mine tab body. The shell keeps every tab alive in an `IndexedStack`,
/// so this waits until the tab is first on screen before it builds (and
/// loads) anything: the entrance cascade then plays once, when the customer
/// opens the tab, instead of unseen at app start — and later tab visits
/// find the page as they left it, with no motion.
class MineBody extends StatefulWidget {
  const MineBody({super.key});

  @override
  State<MineBody> createState() => _MineBodyState();
}

class _MineBodyState extends State<MineBody> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `true` outside a tab stack (the stand-alone Mine route).
    _opened = _opened || Visibility.of(context);
  }

  @override
  Widget build(BuildContext context) =>
      _opened ? const MineContent() : const SizedBox.shrink();
}
