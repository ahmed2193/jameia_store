import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/order_entity.dart';
import '../../../../../core/motion/entrance_cascade.dart';
import '../../../../../core/motion/entrance_cascade_item.dart';
import '../../../../../core/widgets/hero_section_header.dart';
import '../../../domain/entities/order_help_issue.dart';
import 'order_help_issue_section.dart';
import 'order_help_note_field.dart';
import 'order_help_order_card.dart';
import 'order_help_send_bar.dart';

/// The help form, the way delivery apps ask it: which order, "What went
/// wrong?" (grouped choice cards; an issue about items opens the item
/// picker under it), "Tell us more", and the pinned send pill. The blocks
/// rise in once when the options arrive. Reads no state itself: each card
/// selects its own choice and the bar its own send state.
class OrderHelpBody extends StatelessWidget {
  const OrderHelpBody({
    super.key,
    required this.order,
    required this.groups,
    required this.onSend,
  });

  final OrderEntity order;
  final List<OrderHelpIssueGroup> groups;
  final VoidCallback onSend;

  /// Cascade slots taken before the first group.
  static const int _groupsStart = 2;

  @override
  Widget build(BuildContext context) {
    final noteSlot = _groupsStart + groups.length;
    return Column(
      children: [
        Expanded(
          child: EntranceCascade(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: EntranceCascadeItem(
                    index: 0,
                    child: OrderHelpOrderCard(order: order),
                  ),
                ),
                SliverToBoxAdapter(
                  child: EntranceCascadeItem(
                    index: 1,
                    child: HeroSectionHeader(
                      title: 'support.help_issue_title'.tr(),
                      titleStyle: AppTextStyles.groupTitle,
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: groups.length,
                  itemBuilder: (_, index) => EntranceCascadeItem(
                    key: ValueKey(groups[index].category),
                    index: _groupsStart + index,
                    child: OrderHelpIssueSection(
                      group: groups[index],
                      lines: order.lines,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: EntranceCascadeItem(
                    index: noteSlot,
                    child: HeroSectionHeader(
                      title: 'support.help_note_title'.tr(),
                      titleStyle: AppTextStyles.groupTitle,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: EntranceCascadeItem(
                    index: noteSlot + 1,
                    child: const OrderHelpNoteField(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.section),
                ),
              ],
            ),
          ),
        ),
        OrderHelpSendBar(onSend: onSend),
      ],
    );
  }
}
