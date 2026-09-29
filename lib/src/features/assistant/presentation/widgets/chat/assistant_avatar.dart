import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';

/// The assistant's mascot beside its bubbles (decorative: the bubble itself
/// says who is speaking). Still, like every mascot — a thread of rows must
/// not blink in chorus; a [wake] (the chat header, once per open) lets it
/// blink once when the page has settled.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({
    super.key,
    this.size = AppSize.s28,
    this.mood = AssistantMascotMood.idle,
    this.wake,
  });

  final double size;
  final AssistantMascotMood mood;
  final Object? wake;

  @override
  Widget build(BuildContext context) {
    return AssistantMascot(size: size, mood: mood, wake: wake);
  }
}
