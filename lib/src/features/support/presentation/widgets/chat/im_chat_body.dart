import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../domain/entities/support_chat_message.dart';
import 'im_chat_bubble.dart';
import 'im_chat_composer.dart';
import 'im_chat_quick_reply_row.dart';

/// The thread, the quick replies and the composer. Offline: the thread is a
/// scripted conversation in this state; a sent message appends and the rider
/// "echoes" an acknowledgement so the chat feels live. The opening thread
/// cascades in once ([EntranceCascade]); a new bubble rises in at once, and
/// a bubble scrolled back to never replays.
class ImChatBody extends StatefulWidget {
  const ImChatBody({super.key});

  @override
  State<ImChatBody> createState() => _ImChatBodyState();
}

class _ImChatBodyState extends State<ImChatBody> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// Hero canned quick replies shown above the composer.
  static List<String> get _quickReplies => <String>[
    'support.quick_reply_at_door'.tr(),
    'support.quick_reply_call_arrive'.tr(),
    'support.quick_reply_leave_door'.tr(),
    'support.quick_reply_how_long'.tr(),
  ];

  late final List<SupportChatMessage> _messages = <SupportChatMessage>[
    SupportChatMessage(
      text: 'support.msg_picked_up'.tr(),
      mine: false,
      time: '12:31',
    ),
    SupportChatMessage(
      text: 'support.msg_thanks'.tr(),
      mine: true,
      time: '12:31',
    ),
    SupportChatMessage(
      text: 'support.msg_how_long'.tr(),
      mine: true,
      time: '12:32',
    ),
    SupportChatMessage(
      text: 'support.msg_about_ten'.tr(),
      mine: false,
      time: '12:33',
    ),
  ];

  /// Sent this visit and not built yet: each plays its entrance on its first
  /// build only (a lazy list drops and rebuilds rows on scroll-back).
  final Set<SupportChatMessage> _unseen = <SupportChatMessage>{};

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final now = 'support.time_now'.tr();
    final sent = SupportChatMessage(text: text, mine: true, time: now);
    // Scripted rider acknowledgement so the thread feels live offline.
    final echo = SupportChatMessage(
      text: 'support.msg_got_it'.tr(),
      mine: false,
      time: now,
    );
    setState(() {
      _messages.addAll([sent, echo]);
      _unseen.addAll([sent, echo]);
      _input.clear();
    });
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final position = _scroll.position;
      MotionGuard.scrollTo(
        context,
        position,
        position.maxScrollExtent,
        duration: AppMotion.medium,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EntranceCascade(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.s12),
              itemCount: _messages.length,
              // Keyed by the message: the settled bubbles stay put when a new
              // one is appended.
              itemBuilder: (_, i) {
                final message = _messages[i];
                final key = ObjectKey(message);
                if (_unseen.remove(message)) {
                  return EntranceCascadeItem.single(
                    key: key,
                    child: ImChatBubble(message: message),
                  );
                }
                return EntranceCascadeItem(
                  key: key,
                  index: i,
                  child: ImChatBubble(message: message),
                );
              },
            ),
          ),
        ),
        ImChatQuickReplyRow(replies: _quickReplies, onTap: _send),
        ImChatComposer(controller: _input, onSend: _send),
      ],
    );
  }
}
