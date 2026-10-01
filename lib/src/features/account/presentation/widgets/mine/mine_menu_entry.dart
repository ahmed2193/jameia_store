import 'package:flutter/widgets.dart';

import 'mine_tone.dart';

/// What one Mine menu row shows and where it goes.
class MineMenuEntry {
  const MineMenuEntry({
    this.icon,
    this.plate,
    required this.label,
    required this.route,
    this.tone = MineTone.neutral,
    this.badgeCount = 0,
    this.trailing,
  });

  final IconData? icon;

  /// A colour plate (`HeroAssets` path) in place of [icon]'s tinted tile,
  /// see `MineIconTile`.
  final String? plate;
  final String label;
  final String route;
  final MineTone tone;

  /// Unread count shown as a badge; 0 hides it.
  final int badgeCount;

  /// Extra status before the chevron (e.g. the Pro "Active" chip).
  final Widget? trailing;
}
