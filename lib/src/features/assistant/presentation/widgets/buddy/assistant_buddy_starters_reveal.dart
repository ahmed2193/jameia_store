import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/assistant_starter.dart';
import 'assistant_buddy_starters.dart';

/// Unfolds the greeting's starters under the message once it has [typed]
/// out: the card grows smoothly to make room. Reduced motion: they are just
/// there (an `AnimatedSize` of zero duration must not run).
class AssistantBuddyStartersReveal extends StatelessWidget {
  const AssistantBuddyStartersReveal({
    super.key,
    required this.typed,
    required this.starters,
    required this.onStarter,
  });

  final bool typed;
  final List<AssistantStarter> starters;
  final ValueChanged<AssistantStarter> onStarter;

  @override
  Widget build(BuildContext context) {
    final content = typed
        ? Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.s12,
              end: AppSpacing.s10,
            ),
            child: AssistantBuddyStarters(
              starters: starters,
              onStarter: onStarter,
            ),
          )
        : const SizedBox(width: double.infinity);
    if (MotionGuard.reduced(context)) return content;
    return AnimatedSize(
      duration: AppMotion.page,
      curve: AppMotion.emphasizedDecelerate,
      alignment: AlignmentDirectional.topStart,
      child: content,
    );
  }
}
