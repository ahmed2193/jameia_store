import 'package:flutter/material.dart';

import '../../../domain/entities/assistant_starter.dart';

/// The glyph beside each starter, shared by the chat's welcome and the
/// buddy's greeting.
extension AssistantStarterIcons on AssistantStarter {
  IconData get icon => switch (this) {
    AssistantStarter.completeCart => Icons.shopping_basket_outlined,
    AssistantStarter.breakfast => Icons.egg_alt_outlined,
    AssistantStarter.dinner => Icons.restaurant_outlined,
    AssistantStarter.offers => Icons.local_offer_outlined,
    AssistantStarter.order => Icons.local_shipping_outlined,
    AssistantStarter.delivery => Icons.schedule_rounded,
  };
}
