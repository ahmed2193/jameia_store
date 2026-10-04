import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_bidi_text.dart';
import '../../../../core/widgets/hero_line_thumb.dart';

/// The geometry every order line shares, so paid and free rows read as one
/// list: an optional product photo ([thumbUrl]), the quantity (`2×`, one
/// left-to-right tabular run), the name (two lines, [struck] through when
/// the picker could not find it) over an optional [subtitle], an optional
/// [caption] (the unit price on the invoice) and an optional [note] (a tag,
/// a "replaced with" line), and an optional [trailing] value. Names and
/// sizes read in their own direction ([HeroBidiText]): a Latin "2 Liter" in
/// the Arabic app is not turned into "Liter 2". Flat — the list around it
/// draws the hairlines. Read out as one node.
class OrderLineLayout extends StatelessWidget {
  const OrderLineLayout({
    super.key,
    required this.quantity,
    required this.name,
    this.subtitle = '',
    this.subtitleColor,
    this.trailing,
    this.thumbUrl,
    this.struck = false,
    this.caption = '',
    this.note,
  });

  static final TextStyle _quantityStyle = AppTextStyles.label.copyWith(
    color: AppColors.secondaryText,
    fontFeatures: AppTextStyles.tabular,
  );

  static const double _thumb = AppSize.s44;

  /// The value column never takes more: past it (large text, a long
  /// currency) the value scales down and the name keeps its room.
  static const double _maxTrailing = AppSize.s120;

  final int quantity;
  final String name;

  /// Hidden when empty.
  final String subtitle;

  /// Defaults to the grey of [AppTextStyles.meta].
  final Color? subtitleColor;
  final Widget? trailing;

  /// The product photo; `null` = a text-only row (the invoice).
  final String? thumbUrl;
  final bool struck;

  /// A grey line under the subtitle (the unit price); hidden when empty.
  final String caption;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    final subtitleColor = this.subtitleColor;
    final thumbUrl = this.thumbUrl;
    final note = this.note;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpacing.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbUrl != null) ...[
              ExcludeSemantics(
                child: HeroLineThumb(url: thumbUrl, size: _thumb),
              ),
              const SizedBox(width: AppSpacing.s12),
            ],
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text('$quantity×', style: _quantityStyle),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeroBidiText(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: struck
                        ? AppTextStyles.itemTitle.copyWith(
                            color: AppColors.secondaryText,
                            decoration: TextDecoration.lineThrough,
                          )
                        : AppTextStyles.itemTitle,
                  ),
                  if (subtitle.isNotEmpty)
                    HeroBidiText(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subtitleColor == null
                          ? AppTextStyles.meta
                          : AppTextStyles.meta.copyWith(color: subtitleColor),
                    ),
                  // Money is never cut short: it wraps instead.
                  if (caption.isNotEmpty)
                    Text(caption, style: AppTextStyles.meta),
                  if (note != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    note,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.s12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxTrailing),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: trailing,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
