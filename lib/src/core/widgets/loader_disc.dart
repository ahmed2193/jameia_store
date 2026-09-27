import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../motion/fade_through_switcher.dart';
import '../responsive/app_size.dart';
import 'branded_dot_loader.dart';
import 'loader_done_mark.dart';

/// The white loader disc: the Hero dots floating on a white circle with a
/// soft drop, the look of a block load ([AppLoader]) and of the busy scrim
/// ([BusyOverlay]). [done] fades the dots through to a check
/// ([LoaderDoneMark]) for the beat before the screen moves on. Decorative:
/// the owner says what is happening.
class LoaderDisc extends StatelessWidget {
  const LoaderDisc({super.key, this.done = false});

  static const double diameter = AppSize.s96;

  /// The dots take a third of the disc.
  static const double _dotsWidth = AppSize.s32;

  final bool done;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: diameter,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: AppShadows.loaderDisc,
          ),
          child: Center(
            child: FadeThroughSwitcher(
              stateKey: done,
              child: done
                  ? const LoaderDoneMark()
                  : const BrandedDotLoader(size: _dotsWidth),
            ),
          ),
        ),
      ),
    );
  }
}
