import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../chat/assistant_entrance.dart';
import '../chat/assistant_suggestion_chip.dart';
import '../welcome/assistant_starter_icons.dart';

/// The greeting's ways to start, sliding in one after another from the
/// start edge once the message has typed out; a row that scrolls sideways
/// when they do not fit.
class AssistantBuddyStarters extends StatelessWidget {
  const AssistantBuddyStarters({
    super.key,
    required this.starters,
    required this.onStarter,
  });

  final List<AssistantStarter> starters;
  final ValueChanged<AssistantStarter> onStarter;

  static const Duration _stagger = Duration(milliseconds: 50);
  static const Offset _fromStart = Offset(-0.12, 0);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (index, starter) in starters.indexed) ...[
            if (index > 0) const SizedBox(width: AppSpacing.s8),
            AssistantEntrance(
              key: ValueKey<AssistantStarter>(starter),
              delay: _stagger * index,
              beginOffset: _fromStart,
              child: AssistantSuggestionChip(
                label: starter.labelKey.tr(),
                icon: starter.icon,
                onTap: () => onStarter(starter),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
