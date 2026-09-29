import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../domain/entities/assistant_nudge.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_buddy_countdown_bar.dart';
import 'assistant_buddy_greeting_header.dart';
import 'assistant_buddy_starters_reveal.dart';

/// The greeting itself: the mascot, "Good evening, Sara", a line that
/// reveals word by word, then the ways to start unfold beneath — led by the tour on
/// a first meeting ([onTour]) — and the hairline counts down. Tapping the
/// card opens the chat (the tour on a first meeting). A polite live region:
/// screen readers hear it without losing their place.
class AssistantBuddyGreetingCard extends StatelessWidget {
  const AssistantBuddyGreetingCard({
    super.key,
    required this.nudge,
    required this.mood,
    required this.typed,
    required this.countdown,
    required this.showCountdown,
    required this.onTyped,
    required this.onOpen,
    required this.onStarter,
    required this.onClose,
    this.onTour,
  });

  final AssistantNudge nudge;
  final AssistantMascotMood mood;
  final bool typed;
  final Animation<double> countdown;
  final bool showCountdown;
  final VoidCallback onTyped;
  final VoidCallback onOpen;
  final ValueChanged<AssistantStarter> onStarter;
  final VoidCallback onClose;
  final VoidCallback? onTour;

  static const BoxDecoration _card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.r2)),
    border: Border.fromBorderSide(BorderSide(color: AppColors.brandLightBg)),
    boxShadow: AppShadows.high,
  );

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthSessionCubit, String>(
      (session) => session.state.customer?.givenName.trim() ?? '',
    );
    final greeting = name.isEmpty
        ? nudge.dayPart.greetingKey(withName: false).tr()
        : nudge.dayPart
              .greetingKey(withName: true)
              .tr(namedArgs: {'name': name});
    return Semantics(
      container: true,
      liveRegion: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: DecoratedBox(
          decoration: _card,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.s14,
              AppSpacing.s14,
              AppSpacing.s4,
              AppSpacing.s14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AssistantBuddyGreetingHeader(
                  greeting: greeting,
                  message: nudge.message.key.tr(),
                  mood: mood,
                  onTyped: onTyped,
                  onClose: onClose,
                ),
                AssistantBuddyStartersReveal(
                  typed: typed,
                  starters: nudge.starters,
                  onStarter: onStarter,
                  onTour: onTour,
                ),
                if (showCountdown)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSpacing.s12,
                      end: AppSpacing.s10,
                    ),
                    child: AssistantBuddyCountdownBar(elapsed: countdown),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
