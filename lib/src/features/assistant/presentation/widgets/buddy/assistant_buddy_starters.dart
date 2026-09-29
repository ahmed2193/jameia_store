import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../chat/assistant_suggestion_chip.dart';
import '../welcome/assistant_starter_icons.dart';
import 'assistant_buddy_tour_chip.dart';

/// The greeting's ways to start, rising in one after another
/// ([EntranceCascade]) once the message has typed out — led by the tour on a first
/// meeting ([onTour]); a row that scrolls sideways when they do not fit.
class AssistantBuddyStarters extends StatelessWidget {
  const AssistantBuddyStarters({
    super.key,
    required this.starters,
    required this.onStarter,
    this.onTour,
  });

  final List<AssistantStarter> starters;
  final ValueChanged<AssistantStarter> onStarter;
  final VoidCallback? onTour;

  @override
  Widget build(BuildContext context) {
    final onTour = this.onTour;
    final lead = onTour == null ? 0 : 1;
    return EntranceCascade(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            if (onTour != null)
              EntranceCascadeItem(
                key: const ValueKey<String>('tour'),
                index: 0,
                child: AssistantBuddyTourChip(onTap: onTour),
              ),
            for (final (index, starter) in starters.indexed) ...[
              if (index + lead > 0) const SizedBox(width: AppSpacing.s8),
              EntranceCascadeItem(
                key: ValueKey<AssistantStarter>(starter),
                index: index + lead,
                child: AssistantSuggestionChip(
                  label: starter.labelKey.tr(),
                  icon: starter.icon,
                  // The greeting fires the pick itself (it also closes).
                  haptic: null,
                  onTap: () => onStarter(starter),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
