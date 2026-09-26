import 'package:flutter/material.dart';

/// Lifts a bottom sheet's [child] above the keyboard. Only this widget reads
/// the keyboard inset, so each frame of the keyboard sliding in rebuilds this
/// padding alone — the sheet above it and its field, button and header stay.
class CartKeyboardInset extends StatelessWidget {
  const CartKeyboardInset({super.key, required this.child});

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
