import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/thin_divider.dart';
import '../../../domain/entities/assistant_block.dart';
import 'assistant_card_frame.dart';
import 'assistant_location_tile.dart';

/// `locations`: branches / pick-up points, one tile each.
class AssistantLocationsCard extends StatelessWidget {
  const AssistantLocationsCard({super.key, required this.items});

  final List<AssistantLocation> items;

  @override
  Widget build(BuildContext context) {
    return AssistantCardFrame(
      title: 'assistant.locations_title'.tr(),
      icon: HeroIcons.store,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, location) in items.indexed) ...[
            if (index > 0) const ThinDivider(),
            AssistantLocationTile(location: location),
          ],
        ],
      ),
    );
  }
}
