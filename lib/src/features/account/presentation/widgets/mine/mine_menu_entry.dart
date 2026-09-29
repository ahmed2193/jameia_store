import 'package:flutter/widgets.dart';

import 'mine_tone.dart';

/// What one Mine menu row shows and where it goes.
class MineMenuEntry {
  const MineMenuEntry({
    this.icon,
    this.asset,
    this.plate = false,
    required this.label,
    required this.route,
    this.tone = MineTone.neutral,
    this.badgeCount = 0,
    this.trailing,
  });

  final IconData? icon;

  /// A drawn `HeroAssets` glyph in place of [icon] ([plate]: a colour
  /// plate, see `MineIconTile`).
  final String? asset;
  final bool plate;
  final String label;
  final String route;
  final MineTone tone;

  /// Unread count shown as a badge; 0 hides it.
  final int badgeCount;

  /// Extra status before the chevron (e.g. the Pro "Active" chip).
  final Widget? trailing;
}
