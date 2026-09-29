import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../motion/fade_through_switcher.dart';
import '../responsive/app_size.dart';
import 'branded_dot_loader.dart';
import 'loader_done_mark.dart';
import 'loader_fail_mark.dart';

/// The white loader disc: the Hero dots floating on a white circle with a
/// soft drop, the look of a block load ([AppLoader]) and of the busy scrim
/// ([BusyOverlay]). [done] fades the dots through to a check
/// ([LoaderDoneMark]) for the beat before the screen moves on; [failed]
/// fades them through to a drawn × ([LoaderFailMark]) when the work could
/// not finish. Decorative: the owner says what is happening.
class LoaderDisc extends StatelessWidget {
  const LoaderDisc({super.key, this.done = false, this.failed = false});

  static const double diameter = AppSize.s96;

  /// The dots take a third of the disc.
  static const double _dotsWidth = AppSize.s32;

  final bool done;

  /// The work could not finish (ignored while [done]).
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final failing = !done && failed;
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
              stateKey: (done, failing),
              child: done
                  ? const LoaderDoneMark()
                  : failing
                  ? const LoaderFailMark()
                  : const BrandedDotLoader(size: _dotsWidth),
            ),
          ),
        ),
      ),
    );
  }
}
