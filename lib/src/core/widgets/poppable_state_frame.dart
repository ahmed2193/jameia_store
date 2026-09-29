import 'package:flutter/widgets.dart';

import '../../config/theme/app_spacing.dart';
import 'round_back_button.dart';

/// A full-screen state (loader, error, not found) of a pushed page that has
/// no bar of its own yet: the round back button sits at the top start over
/// it, so no state of a presentation ever leaves the customer without a way
/// out (docs/motion B2-08). Nothing extra on a root route.
class PoppableStateFrame extends StatelessWidget {
  const PoppableStateFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(child: child),
          if (canPop)
            const PositionedDirectional(
              top: AppSpacing.s8,
              start: AppSpacing.s12,
              child: RoundBackButton(),
            ),
        ],
      ),
    );
  }
}
