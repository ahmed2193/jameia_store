import 'package:flutter/material.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../domain/entities/assistant_starter.dart';

/// The glyph beside each starter, shared by the chat's welcome and the
/// buddy's greeting.
extension AssistantStarterIcons on AssistantStarter {
  IconData get icon => switch (this) {
    AssistantStarter.completeCart => HeroIcons.basket,
    AssistantStarter.breakfast => HeroIcons.egg,
    AssistantStarter.dinner => HeroIcons.cutlery,
    AssistantStarter.offers => HeroIcons.tag,
    AssistantStarter.order => HeroIcons.delivery,
    AssistantStarter.delivery => HeroIcons.clock,
  };
}
