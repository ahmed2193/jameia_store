import 'package:flutter/widgets.dart';

/// Pads [child] by the keyboard height. Only this padding rebuilds while the
/// keyboard animates, not the widget that places it.
class KeyboardInsetPadding extends StatelessWidget {
  const KeyboardInsetPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}
