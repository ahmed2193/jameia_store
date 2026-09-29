import 'package:flutter/widgets.dart';

import '../../config/theme/app_spacing.dart';
import 'hero_snack_glyph.dart';
import 'hero_snack_message.dart';

/// One snack bar message laid out: the tone glyph, then the words (the
/// snack bar theme's text style).
class HeroSnackLine extends StatelessWidget {
  const HeroSnackLine({super.key, required this.message});

  final HeroSnackMessage message;

  @override
  Widget build(BuildContext context) {
    final plain = message.tone == HeroSnackTone.info;
    return Row(
      children: [
        if (!plain) ...[
          HeroSnackGlyph(tone: message.tone),
          const SizedBox(width: AppSpacing.s12),
        ],
        Expanded(child: Text(message.text)),
      ],
    );
  }
}
