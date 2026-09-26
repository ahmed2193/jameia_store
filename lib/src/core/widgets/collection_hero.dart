import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';
import 'collection_hero_emoji.dart';
import 'wavy_edge_painter.dart';

/// The tinted top of a collection page (offers, flash deals, best sellers):
/// a big heavy heading with an optional emoji ("Best sellers near you 🔥"),
/// an optional line under it and an optional [trailing] (a countdown), on a
/// warm band whose bottom is a hand-drawn wave. The heading rises in as the
/// page opens; the emoji wiggles once after it.
///
/// Reports its laid-out height through [onExtent], so the app bar above can
/// finish turning white exactly as the band scrolls away.
class CollectionHero extends StatefulWidget {
  const CollectionHero({
    super.key,
    required this.heading,
    this.emoji,
    this.subtitle,
    this.trailing,
    this.color = AppColors.collectionCream,
    this.onExtent,
  });

  final String heading;
  final String? emoji;
  final String? subtitle;
  final Widget? trailing;
  final Color color;
  final ValueChanged<double>? onExtent;

  /// How far the wave dips under the band.
  static const double waveDepth = AppSpacing.s12;

  @override
  State<CollectionHero> createState() => _CollectionHeroState();
}

class _CollectionHeroState extends State<CollectionHero> {
  static const FontWeight _heavy = FontWeight.w800;
  static const double _lineHeight = 1.15;
  static const double _rise = AppSpacing.s16;

  double? _reported;

  void _report() {
    final box = context.findRenderObject();
    if (!mounted || box is! RenderBox || !box.hasSize) return;
    final extent = box.size.height;
    if (extent == _reported) return;
    _reported = extent;
    widget.onExtent?.call(extent);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    final headingStyle = AppTextStyles.displayMedium.copyWith(
      fontSize: AppSize.font24,
      fontWeight: _heavy,
      height: _lineHeight,
      color: AppColors.primaryText,
    );
    final emoji = widget.emoji;
    return CustomPaint(
      painter: WavyEdgePainter(
        color: widget.color,
        depth: CollectionHero.waveDepth,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s16,
          AppSpacing.s8,
          AppSpacing.s16,
          AppSpacing.s24 + CollectionHero.waveDepth,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: MotionGuard.duration(context, AppMotion.slow),
          curve: AppMotion.emphasizedDecelerate,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * _rise),
              child: child,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  text: widget.heading,
                  children: [
                    if (emoji != null)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: AppSpacing.s6,
                          ),
                          child: CollectionHeroEmoji(
                            emoji: emoji,
                            style: headingStyle,
                            delay: AppMotion.slow,
                          ),
                        ),
                      ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: headingStyle,
              ),
              if (widget.subtitle case final subtitle?) ...[
                const SizedBox(height: AppSpacing.s6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
              if (widget.trailing case final trailing?) ...[
                const SizedBox(height: AppSpacing.s12),
                trailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
