import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/assistant_day_part.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../chat/assistant_entrance.dart';
import '../chat/assistant_suggestion_chip.dart';

/// Four ways to start, picked for this moment ("Complete my cart" when the
/// cart has something, breakfast in the morning, dinner in the evening,
/// then offers / orders / delivery). Each chip shows a short label and
/// sends a full question; they enter one after another from the start edge.
class AssistantStarterChips extends StatelessWidget {
  const AssistantStarterChips({super.key});

  static const Duration _stagger = Duration(milliseconds: 40);
  static const Offset _fromStart = Offset(-0.06, 0);

  static IconData _iconOf(AssistantStarter starter) => switch (starter) {
    AssistantStarter.completeCart => Icons.shopping_basket_outlined,
    AssistantStarter.breakfast => Icons.egg_alt_outlined,
    AssistantStarter.dinner => Icons.restaurant_outlined,
    AssistantStarter.offers => Icons.local_offer_outlined,
    AssistantStarter.order => Icons.local_shipping_outlined,
    AssistantStarter.delivery => Icons.schedule_rounded,
  };

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
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      alignment: WrapAlignment.center,
      children: [
        for (final (index, starter) in starters.indexed)
          AssistantEntrance(
            key: ValueKey<AssistantStarter>(starter),
            delay: _stagger * index,
            beginOffset: _fromStart,
            curve: AppMotion.signature,
            child: AssistantSuggestionChip(
              label: starter.labelKey.tr(),
              icon: _iconOf(starter),
              onTap: canSend
                  ? () => context.read<AssistantChatCubit>().send(
                      starter.promptKey.tr(),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}
