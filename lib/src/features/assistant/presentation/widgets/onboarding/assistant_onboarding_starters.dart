import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../domain/entities/assistant_day_part.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../chat/assistant_suggestion_chip.dart';
import '../welcome/assistant_starter_icons.dart';

/// The last step's ways to start — picked for this moment like the chat's
/// welcome — rising in one after another once the step first comes in
/// front ([active]; at rest on a step already [played]), in one
/// row that scrolls sideways when they do not fit (the demo above keeps its
/// room). A tap closes the tour and opens the chat with that question.
class AssistantOnboardingStarters extends StatelessWidget {
  const AssistantOnboardingStarters({
    super.key,
    required this.active,
    this.played = false,
    required this.onStarter,
  });

  final bool active;
  final bool played;
  final ValueChanged<AssistantStarter> onStarter;

  static const int _count = 3;

  /// The chips follow the caption's two lines.
  static const int _firstStep = 2;

  @override
  Widget build(BuildContext context) {
    final hasCartItems = context.select<CartCubit, bool>(
      (cart) => cart.state.totalQty > 0,
    );
    final starters = AssistantStarter.pick(
      dayPart: AssistantDayPart.of(DateTime.now()),
      hasCartItems: hasCartItems,
    ).take(_count);
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final (index, starter) in starters.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.s8),
              EntranceCascadeItem.single(
                key: ValueKey<(AssistantStarter, bool)>((starter, active)),
                play: active && !played,
                index: _firstStep + index,
                child: AssistantSuggestionChip(
                  label: starter.labelKey.tr(),
                  icon: starter.icon,
                  onTap: () => onStarter(starter),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
