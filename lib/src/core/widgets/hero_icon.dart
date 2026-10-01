import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../design/hero_icon_fill_colors.dart';
import '../design/hero_icon_tone.dart';
import '../design/hero_icons.dart';

/// A Hero icon in the sticker style of the art in `assets/svg` — the drop-in
/// replacement for [Icon].
///
/// The colour it would have as an [Icon] ([color], else the ambient
/// [IconTheme] colour) picks the look:
/// - **Sticker** — an ink colour (`primaryText`, `stickerOutline`,
///   [HeroColors.iconInk], `primaryDark`, `brandDeep`, `primary`, `black`, or
///   none): the line glyph in [HeroColors.iconInk] over its accent layer
///   (`HeroIcons.accentOf`) in the icon's natural fill (`HeroIcons.fillOf`).
///   An icon without an accent layer draws its ink line only.
/// - **Tone** — [tone] given: the tone's line over the tone's accent, whatever
///   the colour (content marks that keep a fixed pair).
/// - **Mono** — [mono], or any other colour (white on a brand or dark fill,
///   secondary / disabled text, error red, Pro indigo, link blue…): a plain
///   one-colour [Icon], so contrast and meaning stay as they were.
///
/// Size and opacity follow the [IconTheme]; directional glyphs flip in RTL on
/// their own; only the line glyph carries [semanticLabel].
class HeroIcon extends StatelessWidget {
  const HeroIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.tone,
    this.mono = false,
    this.shadows,
  });

  final IconData icon;

  /// Defaults to the ambient [IconTheme] size.
  final double? size;

  /// Defaults to the ambient [IconTheme] colour.
  final Color? color;
  final String? semanticLabel;

  /// A fixed line / accent pair instead of the ink + natural fill.
  final HeroIconTone? tone;

  /// One colour only, even for an ink colour.
  final bool mono;

  /// Shadows under the line glyph (a glow on a ghost hand, say).
  final List<Shadow>? shadows;

  /// The colours that read as ink and turn an icon into a sticker, besides the
  /// theme's own `primaryText` and `iconInk`.
  static const List<Color> inkColors = [
    AppColors.primaryText,
    AppColors.stickerOutline,
    AppColors.primaryDark,
    AppColors.brandDeep,
    AppColors.primary,
    AppColors.black,
  ];

  static bool _isInk(Color? color, HeroColors? palette) =>
      color == null ||
      inkColors.contains(color) ||
      color == palette?.primaryText ||
      color == palette?.iconInk;

  @override
  Widget build(BuildContext context) {
    final Color? effective = color ?? IconTheme.of(context).color;
    final HeroColors? palette = Theme.of(context).extension<HeroColors>();
    final (Color? lineColor, Color? accentColor) = switch (tone) {
      _ when mono => (color, null),
      final HeroIconTone pair => (pair.line, pair.accent),
      null when _isInk(effective, palette) => (
        palette?.iconInk ?? AppColors.stickerOutline,
        HeroIcons.fillOf(icon)?.color,
      ),
      null => (color, null),
    };
    final Widget line = Icon(
      icon,
      size: size,
      color: lineColor,
      semanticLabel: semanticLabel,
      shadows: shadows,
    );
    final IconData? accent = accentColor == null
        ? null
        : HeroIcons.accentOf(icon);
    if (accent == null) return line;
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        ExcludeSemantics(
          child: Icon(accent, size: size, color: accentColor),
        ),
        line,
      ],
    );
  }
}
