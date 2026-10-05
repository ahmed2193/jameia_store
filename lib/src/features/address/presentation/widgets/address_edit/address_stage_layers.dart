import 'package:flutter/material.dart';

import '../../../../../core/motion/motion.dart';
import '../../../../../core/navigation/hero_through_transition.dart';

/// The two layers of the address screen. Under: the [mapStage], once made
/// ([mapMade]) kept alive for the way back — out of the picture while the
/// form fully covers it ([mapAway]), deaf and silent while the form is up
/// ([details]). Over: the [form] while it is up or on its way, moving with
/// [motion] (the forward push motion).
class AddressStageLayers extends StatelessWidget {
  const AddressStageLayers({
    super.key,
    required this.mapStage,
    required this.mapMade,
    required this.mapAway,
    required this.details,
    required this.formShown,
    required this.motion,
    required this.form,
  });

  final Widget mapStage;
  final bool mapMade;
  final bool mapAway;

  /// The form is up (or coming up): it takes the taps, not the map.
  final bool details;
  final bool formShown;
  final Animation<double> motion;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (mapMade)
          Visibility(
            visible: !mapAway,
            maintainState: true,
            child: ExcludeSemantics(
              excluding: details,
              child: IgnorePointer(ignoring: details, child: mapStage),
            ),
          ),
        if (formShown)
          IgnorePointer(
            ignoring: !details,
            child: HeroThroughTransition(
              animation: motion,
              shift: MotionGuard.reduced(context) ? 0 : AppMotion.slideShift,
              child: form,
            ),
          ),
      ],
    );
  }
}
