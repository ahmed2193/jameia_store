import 'package:flutter/widgets.dart';

/// Lifts the cancel sheet's content above the keyboard. A widget of its own
/// so each frame of the keyboard animation rebuilds only this padding, never
/// the sheet's rows, note field and button ([child] is handed back as is).
class CancelOrderSheetInsets extends StatelessWidget {
  const CancelOrderSheetInsets({super.key, required this.child});

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
