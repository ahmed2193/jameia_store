import 'package:flutter/material.dart';

/// Keeps a paywall section alive when it scrolls far out of the lazy list,
/// so its one-shot entrance (the tabs dropping in, the hero drawing itself,
/// the card revealing) plays once instead of again on the way back.
class ProKeepAlive extends StatefulWidget {
  const ProKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<ProKeepAlive> createState() => _ProKeepAliveState();
}

class _ProKeepAliveState extends State<ProKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
