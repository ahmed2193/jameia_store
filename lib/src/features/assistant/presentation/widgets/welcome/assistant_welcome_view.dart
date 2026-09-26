import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import 'assistant_continue_tile.dart';
import 'assistant_disclaimer.dart';
import 'assistant_starter_chips.dart';
import 'assistant_welcome_hero.dart';

/// A chat with no message yet: who the assistant is, the last open chat to
/// continue, four starters and the "can make mistakes" line.
class AssistantWelcomeView extends StatelessWidget {
  const AssistantWelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      children: const [
        AssistantWelcomeHero(),
        SizedBox(height: AppSpacing.s20),
        AssistantContinueTile(),
        AssistantStarterChips(),
        SizedBox(height: AppSpacing.s20),
        AssistantDisclaimer(),
      ],
    );
  }
}
