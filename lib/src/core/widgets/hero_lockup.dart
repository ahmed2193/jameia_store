import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_mark_painting.dart';
import '../design/hero_wordmark.dart';
import '../motion/idle_loop.dart';
import 'hero_lockup_painter.dart';

/// The Hero logo as the splash leaves it — the bag in its cape over the name
/// ("hero", or "هيرو" in Arabic) — at a size set by the name's height
/// [wordHeight]. While [alive], the cape ripples and the bag bobs, so a
/// header that holds the logo feels awake; still under reduced motion. The
/// name is read out as the app's name for screen readers.
class HeroLockup extends StatelessWidget {
  const HeroLockup({
    super.key,
    required this.wordHeight,
    required this.semanticLabel,
    this.markColors = HeroMarkColors.onBrand,
    this.wordColor = AppColors.white,
    this.alive = true,
  });

  final double wordHeight;
  final String semanticLabel;
  final HeroMarkColors markColors;
  final Color wordColor;
  final bool alive;

  @override
  Widget build(BuildContext context) {
    final wordmark = HeroWordmark.forLanguage(
      Localizations.localeOf(context).languageCode,
    );
    return Semantics(
      label: semanticLabel,
      image: true,
      child: RepaintBoundary(
        child: IdleLoop(
          running: alive,
          builder: (context, loop) => CustomPaint(
            size: HeroLockupPainter.sizeFor(wordHeight, wordmark),
            painter: HeroLockupPainter(
              idle: loop,
              wordHeight: wordHeight,
              wordmark: wordmark,
              markColors: markColors,
              wordColor: wordColor,
            ),
          ),
        ),
      ),
    );
  }
}
