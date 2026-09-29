import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import 'assistant_mascot.dart';
import 'assistant_mascot_mood.dart';

/// The painted mascot with one of its drawn props beside it (a
/// `HeroAssets.assistantProp*` SVG, docs/motion/asset_manifest.md batch A):
/// the empty history's speech bubble, the blocked mic, the teammate it
/// hands over to. The mascot stands at the start, the prop at the end; a
/// [directional] prop (a tail, a reaching hand pointing at the mascot) is
/// mirrored in RTL so it still points at it — and the mascot with it, so a
/// mood that looks aside ([AssistantMascotMood.handingOver]) still looks at
/// the prop. Still unless the mascot's own
/// gestures play; decorative — the words around it carry the meaning.
class AssistantPropScene extends StatelessWidget {
  const AssistantPropScene({
    super.key,
    required this.prop,
    this.mood = AssistantMascotMood.warm,
    this.directional = false,
    this.mascotSize = AppSize.s56,
    this.propSize = AppSize.s72,
  });

  /// A `HeroAssets` prop path.
  final String prop;
  final AssistantMascotMood mood;
  final bool directional;
  final double mascotSize;
  final double propSize;

  @override
  Widget build(BuildContext context) {
    final mirror =
        directional && Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Transform.flip(
            flipX: mirror,
            child: AssistantMascot(size: mascotSize, mood: mood),
          ),
          const SizedBox(width: AppSpacing.s4),
          SvgPicture.asset(
            prop,
            width: propSize,
            height: propSize,
            matchTextDirection: directional,
          ),
        ],
      ),
    );
  }
}
