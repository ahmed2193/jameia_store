import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../domain/entities/assistant_block.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_suggestion_chip.dart';

/// The follow-ups of the latest reply: at most [maxChips], wrapping (never a
/// clipped single line at large text), rising in one after another
/// ([EntranceCascade]). A tap sends the chip's prompt — the bubble shows what was
/// sent — and retires the row.
class AssistantSuggestionChips extends StatelessWidget {
  const AssistantSuggestionChips({
    super.key,
    required this.suggestions,
    this.animate = true,
  });

  final List<AssistantSuggestion> suggestions;

  /// Enter one after another (a reply that just landed); `false` for a
  /// conversation opened from history.
  final bool animate;

  static const int maxChips = 4;

  @override
  Widget build(BuildContext context) {
    return EntranceCascade(
      play: animate,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.s32),
        child: Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final (index, suggestion)
                in suggestions.take(maxChips).indexed)
              EntranceCascadeItem(
                index: index,
                child: AssistantSuggestionChip(
                  label: suggestion.label,
                  onTap: () => context.read<AssistantChatCubit>().send(
                    suggestion.prompt,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
