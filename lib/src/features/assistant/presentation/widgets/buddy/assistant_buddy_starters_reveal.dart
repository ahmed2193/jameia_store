import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../domain/entities/assistant_starter.dart';
import 'assistant_buddy_starters.dart';

/// Unfolds the greeting's starters under the message once it has [typed]
/// out ([CollapseReveal]: the card's height eases open over the medium
/// beat while the chips mount and rise in — mounted when ready, not on a
/// timer). Reduced motion: they are just there.
class AssistantBuddyStartersReveal extends StatelessWidget {
  const AssistantBuddyStartersReveal({
    super.key,
    required this.typed,
    required this.starters,
    required this.onStarter,
    this.onTour,
  });

  final bool typed;
  final List<AssistantStarter> starters;
  final ValueChanged<AssistantStarter> onStarter;

  /// Leads with the tour (a first meeting).
  final VoidCallback? onTour;

  @override
  Widget build(BuildContext context) {
    return CollapseReveal(
      visible: typed,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          top: AppSpacing.s12,
          end: AppSpacing.s10,
        ),
        child: AssistantBuddyStarters(
          starters: starters,
          onStarter: onStarter,
          onTour: onTour,
        ),
      ),
    );
  }
}
