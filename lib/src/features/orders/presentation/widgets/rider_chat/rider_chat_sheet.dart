import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_sheet_header.dart';
import '../../cubit/rider_chat_cubit.dart';
import '../../cubit/rider_chat_state.dart';
import 'rider_chat_composer.dart';
import 'rider_chat_list.dart';
import 'rider_chat_quick_replies.dart';
import 'rider_chat_typing.dart';

/// The chat with the rider, as a tall sheet over the live map (the ride
/// keeps moving behind it): the conversation, "typing…", the one-tap
/// replies and the composer, lifted above the keyboard and kept below the
/// status bar. When the room is short (landscape with the keyboard up) the
/// "translated" note, the one-tap replies and "typing…" fold away and the
/// composer keeps to one line, so the conversation keeps its space. While
/// it is open every message counts as read.
class RiderChatSheet extends StatefulWidget {
  const RiderChatSheet({super.key, required this.riderName});

  final String riderName;

  @override
  State<RiderChatSheet> createState() => _RiderChatSheetState();
}

class _RiderChatSheetState extends State<RiderChatSheet> {
  late final RiderChatCubit _chat = context.read<RiderChatCubit>();

  /// The failure being told came from a send (the words stay in the box).
  bool _sendFailed = false;

  /// The sheet's height as a share of the screen, keyboard down.
  static const double _heightShare = 0.8;

  /// Below this height the sheet folds its optional rows away.
  static const double _roomyHeight = AppSize.s320;

  /// The least the sheet takes: its header, the divider and a one-line
  /// composer. On a screen shorter than that (landscape, keyboard up) it
  /// reaches under the status bar rather than overflow.
  static const double _floor = AppSize.s160;

  @override
  void initState() {
    super.initState();
    _chat.opened();
  }

  @override
  void dispose() {
    _chat.closed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // The status bar, read from the screen itself: inside a modal sheet the
    // route has taken the top padding away, so `paddingOf` says 0.
    final statusBar = MediaQueryData.fromView(View.of(context)).padding.top;
    final height = math.max(
      _floor,
      math.min(screen * _heightShare, screen - keyboard - statusBar),
    );
    final tight = height < _roomyHeight;
    return BlocListener<RiderChatCubit, RiderChatState>(
      listenWhen: (before, now) {
        if (now.failure == null || before.failure == now.failure) return false;
        _sendFailed = before.sending;
        return true;
      },
      listener: (context, state) =>
          showFailureSnackBar(context, state.failure!, action: _sendFailed),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: height,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                HeroSheetHeader(
                  title: 'orders.chat_title'.tr(
                    namedArgs: {'rider': widget.riderName},
                  ),
                ),
                CollapseReveal(
                  visible: !tight,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.gutter,
                    ),
                    child: Text(
                      'orders.chat_translated'.tr(),
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
                const Divider(height: AppSpacing.s16),
                const Expanded(child: RiderChatList()),
                CollapseReveal(
                  visible: !tight,
                  child: RiderChatTyping(riderName: widget.riderName),
                ),
                CollapseReveal(
                  visible: !tight,
                  child: const RiderChatQuickReplies(),
                ),
                RiderChatComposer(compact: tight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
