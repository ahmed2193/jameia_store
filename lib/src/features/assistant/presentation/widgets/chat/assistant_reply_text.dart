import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../domain/entities/assistant_rich_text.dart';
import '../mascot/assistant_mascot_mood.dart';
import 'assistant_avatar.dart';
import 'assistant_text_bubble.dart';
import 'assistant_thinking_bubble.dart';

/// The text slot of a reply — ONE shell from the first wait to the last
/// word (docs/motion §9.6 §2.2): the avatar, then the thinking bubble
/// ([typing]: no word yet) or the words. The row shows only after
/// [AppMotion.loaderDelay] (a reply faster than that never flashes dots),
/// then enters once ([EntranceCascadeItem.single], when [animate]); the
/// thinking → words swap cross-fades over `fast` while the height eases
/// over `medium` ([SizeFadeSwitcher]), and the avatar keeps its place,
/// easing from its thinking face to idle. A retried reply turns back into
/// the thinking bubble in the same place.
class AssistantReplyText extends StatefulWidget {
  const AssistantReplyText({
    super.key,
    required this.richText,
    this.typing = false,
    this.toolName,
    this.streaming = false,
    this.animate = false,
  });

  final AssistantRichText richText;
  final bool typing;
  final String? toolName;
  final bool streaming;

  /// A reply that starts in this session's flow (it enters once).
  final bool animate;

  @override
  State<AssistantReplyText> createState() => _AssistantReplyTextState();
}

class _AssistantReplyTextState extends State<AssistantReplyText> {
  /// Read once at mount: later rebuilds of the row pass `animate: false`.
  late final bool _enters;
  late bool _waiting;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _enters = widget.animate;
    _waiting = widget.animate && widget.typing;
    if (_waiting) _delay = Timer(AppMotion.loaderDelay, _stopWaiting);
  }

  @override
  void didUpdateWidget(AssistantReplyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The first words beat the delay: they show at once, no dots ever.
    if (_waiting && !widget.typing) _stopWaiting(rebuild: false);
  }

  void _stopWaiting({bool rebuild = true}) {
    _delay?.cancel();
    _delay = null;
    if (!_waiting || !mounted) return;
    if (rebuild) {
      setState(() => _waiting = false);
    } else {
      _waiting = false;
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typing = widget.typing;
    if (_waiting || (!typing && widget.richText.isEmpty)) {
      return const SizedBox.shrink();
    }
    return EntranceCascadeItem.single(
      play: _enters,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssistantAvatar(
            mood: typing
                ? AssistantMascotMood.thinking
                : AssistantMascotMood.idle,
          ),
          const SizedBox(width: AppSpacing.s8),
          Flexible(
            child: SizeFadeSwitcher(
              stateKey: typing,
              fade: AppMotion.fast,
              child: typing
                  ? AssistantThinkingBubble(toolName: widget.toolName)
                  : AssistantTextBubble(
                      richText: widget.richText,
                      streaming: widget.streaming,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
