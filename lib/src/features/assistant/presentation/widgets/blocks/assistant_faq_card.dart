import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';
import 'assistant_faq_row.dart';

/// `faq`: store answers as an accordion; each question folds on its own.
class AssistantFaqCard extends StatelessWidget {
  const AssistantFaqCard({super.key, required this.items});

  final List<AssistantFaqItem> items;

  @override
  Widget build(BuildContext context) {
    return AssistantCardFrame(
      title: 'assistant.faq_title'.tr(),
      icon: HeroIcons.help,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const ThinDivider(),
            AssistantFaqRow(key: ValueKey(item.id), item: item),
          ],
        ],
      ),
    );
  }
}
