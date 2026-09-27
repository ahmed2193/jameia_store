import 'package:flutter/widgets.dart';

/// Lifts [child] above the keyboard. Only this widget reads the keyboard
/// inset, so each frame of the keyboard sliding in rebuilds this padding
/// alone — the sheet or form above it ([child] is handed back as is) stays.
class KeyboardInsetPadding extends StatelessWidget {
  const KeyboardInsetPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    );
  }
}
