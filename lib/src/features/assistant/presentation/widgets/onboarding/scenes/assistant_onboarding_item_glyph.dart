import 'package:flutter/material.dart';

import 'assistant_onboarding_item.dart';

/// A demo item's glyph on its tinted disc, [size] across.
class AssistantOnboardingItemGlyph extends StatelessWidget {
  const AssistantOnboardingItemGlyph({
    super.key,
    required this.item,
    required this.size,
  });

  final AssistantOnboardingItem item;
  final double size;

  static const double _glyphShare = 0.55;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: item.tint, shape: BoxShape.circle),
        child: Icon(item.icon, size: size * _glyphShare, color: item.color),
      ),
    );
  }
}
