import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/assistant_day_part.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../chat/assistant_suggestion_chip.dart';
import 'assistant_starter_icons.dart';

/// Four ways to start, picked for this moment ("Complete my cart" when the
/// cart has something, breakfast in the morning, dinner in the evening,
/// then offers / orders / delivery). Each chip shows a short label and
/// sends a full question; they rise in one after another ([EntranceCascade]).
class AssistantStarterChips extends StatelessWidget {
  const AssistantStarterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final canSend = context.select<AssistantChatCubit, bool>(
      (cubit) => cubit.state.canSend,
    );
    final hasCartItems = context.select<CartCubit, bool>(
      (cart) => cart.state.totalQty > 0,
    );
    final starters = AssistantStarter.pick(
      dayPart: AssistantDayPart.of(DateTime.now()),
      hasCartItems: hasCartItems,
    );
    return EntranceCascade(
      child: Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        alignment: WrapAlignment.center,
        children: [
          for (final (index, starter) in starters.indexed)
            EntranceCascadeItem(
              key: ValueKey<AssistantStarter>(starter),
              index: index,
              child: AssistantSuggestionChip(
                label: starter.labelKey.tr(),
                icon: starter.icon,
                onTap: canSend
                    ? () => context.read<AssistantChatCubit>().send(
                        starter.promptKey.tr(),
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
