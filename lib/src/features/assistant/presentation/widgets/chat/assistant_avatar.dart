import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';

/// The assistant's mascot beside its bubbles (decorative: the bubble itself
/// says who is speaking). Still by default — a thread of rows must not blink
/// in chorus; the one in the header or the welcome is [alive].
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({
    super.key,
    this.size = AppSize.s28,
    this.mood = AssistantMascotMood.idle,
    this.alive = false,
  });

  final double size;
  final AssistantMascotMood mood;
  final bool alive;

  @override
  Widget build(BuildContext context) {
    return AssistantMascot(size: size, mood: mood, alive: alive);
  }
}
