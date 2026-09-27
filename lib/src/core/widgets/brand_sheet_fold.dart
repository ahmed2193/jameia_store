import 'package:flutter/widgets.dart';

import 'brand_sheet_scope.dart';

/// A block of a brand sheet that makes room for the keyboard with the
/// header: it folds away (height and fade) as the header folds, in step with
/// it ([BrandSheetScope.foldOf]), and comes back when the keyboard goes.
/// Outside a brand sheet it just shows [child].
class BrandSheetFold extends StatelessWidget {
  const BrandSheetFold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final open = ReverseAnimation(BrandSheetScope.foldOf(context));
    return FadeTransition(
      opacity: open,
      child: SizeTransition(
        sizeFactor: open,
        alignment: AlignmentDirectional.topCenter,
        child: child,
      ),
    );
  }
}
