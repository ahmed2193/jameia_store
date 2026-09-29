import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/blocked_tap_shake.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../../../../core/widgets/hero_submit_button.dart';
import '../../../domain/entities/order_help_request.dart';
import '../../cubit/order_help_cubit.dart';

/// The pinned "Send to support" pill. Above it, a quiet line says what is
/// still missing (the issue, then its items); a tap before that shakes the
/// pill. While it sends the page's busy overlay holds the screen and the
/// pill keeps its label. It owns these selects, so a pick that flips "can
/// send" rebuilds this bar only.
class OrderHelpSendBar extends StatelessWidget {
  const OrderHelpSendBar({super.key, required this.onSend});

  final VoidCallback onSend;

  static String? _hintKey(OrderHelpGap? gap) => switch (gap) {
    OrderHelpGap.issue => 'support.help_pick_issue',
    OrderHelpGap.products => 'support.help_pick_items',
    OrderHelpGap.noteTooLong => 'support.help_note_too_long',
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final gap = context.select<OrderHelpCubit, OrderHelpGap?>(
      (cubit) => cubit.state.request.gap,
    );
    final sending = context.select<OrderHelpCubit, bool>(
      (cubit) => cubit.state.isSending,
    );
    final sent = context.select<OrderHelpCubit, bool>(
      (cubit) => cubit.state.sent,
    );
    final hint = _hintKey(gap);
    return HeroBottomBar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Closing, it keeps the last line it showed.
          CollapseReveal(
            visible: hint != null,
            child: hint == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: AppSpacing.s8,
                    ),
                    // Centred on the bar (the reveal lets it shrink).
                    child: Center(
                      child: Text(
                        hint.tr(),
                        style: AppTextStyles.meta,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
          BlockedTapShake(
            blocked: gap != null && !sending && !sent,
            child: HeroSubmitButton(
              label: 'support.help_send'.tr(),
              holding: sending || sent,
              enabled: gap == null,
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
