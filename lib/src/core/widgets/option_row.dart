import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/haptics.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';
import './hero_icon.dart';
import 'hero_list_row.dart';
import 'hero_radio_mark.dart';
import 'press_row.dart';

/// How an [OptionRow] sits in its list.
enum OptionRowLook {
  /// The 16 dp gutter, a 24 dp icon and a 16 dp gap (the cancel sheet).
  plain,

  /// Hero's flat choice row: the 12 dp gutter of a dense `HeroListRow`,
  /// the art in a 20 dp slot and the text at
  /// `HeroListRow.denseTextStart`, a quiet 12 sp grey sub-line.
  dense,

  /// The dense row inside Hero's choice card: white with a hairline, mint
  /// with a green hairline and a stronger title once chosen.
  card,
}

/// A choice row (checkout timing / payment / branch, cancel reasons): an
/// optional icon (or a [leading] widget in its place), the title and a grey
/// subtitle, an optional trailing widget and the radio at the end. At least
/// 56 dp tall; announced as a checked / unchecked member of its group, with
/// a selection haptic on tap. Disabled rows ignore taps; a [look] other than
/// [OptionRowLook.plain] shows it in the disabled colours (no dimming layer,
/// so a caller dims its own art), the plain look dims the whole row.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.trailing,
    this.icon,
    this.iconColor,
    this.leading,
    this.look = OptionRowLook.plain,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget? trailing;
  final IconData? icon;

  /// The [icon]'s colour while enabled (ink by default).
  final Color? iconColor;

  /// Art in the icon's place (e.g. a payment method's plate); wins over
  /// [icon] when both are set.
  final Widget? leading;
  final OptionRowLook look;

  static const double _disabledOpacity = 0.45;
  static const BorderRadius _cardRadius = BorderRadius.all(
    Radius.circular(AppRadius.card),
  );

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final icon = this.icon;
    final plain = look == OptionRowLook.plain;
    final card = look == OptionRowLook.card;
    final muted = !enabled && !plain;
    final iconSize = plain ? AppSize.s24 : HeroListRow.denseLeadSize;
    final art =
        leading ??
        (icon == null
            ? null
            : HeroIcon(
                icon,
                size: iconSize,
                color: muted
                    ? AppColors.disabledText
                    : iconColor ?? AppColors.primaryText,
              ));
    final titleStyle = card && selected
        ? AppTextStyles.itemTitleStrong
        : AppTextStyles.itemTitle;
    final subtitleStyle = plain
        ? AppTextStyles.meta
        : AppTextStyles.bodySmall.copyWith(color: AppColors.labelGrey);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.s56),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: plain ? AppSpacing.gutter : HeroListRow.denseInset,
          vertical: AppSpacing.s12,
        ),
        child: Row(
          children: [
            if (art != null) ...[
              if (plain)
                art
              else
                SizedBox.square(
                  dimension: HeroListRow.denseLeadSize,
                  child: Center(
                    child: FittedBox(fit: BoxFit.scaleDown, child: art),
                  ),
                ),
              SizedBox(width: plain ? AppSpacing.s16 : HeroListRow.denseGap),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: muted
                        ? titleStyle.copyWith(color: AppColors.tertiaryText)
                        : titleStyle,
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      subtitle,
                      style: muted
                          ? subtitleStyle.copyWith(
                              color: AppColors.tertiaryText,
                            )
                          : subtitleStyle,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.s8),
              trailing!,
            ],
            const SizedBox(width: AppSpacing.s12),
            HeroRadioMark(selected: selected),
          ],
        ),
      ),
    );
    final ink = PressRow(
      onTap: enabled
          ? () {
              Haptics.pick();
              onTap();
            }
          : null,
      borderRadius: card ? _cardRadius : null,
      child: row,
    );
    final body = switch (look) {
      OptionRowLook.plain => Opacity(
        opacity: enabled ? 1 : _disabledOpacity,
        child: ink,
      ),
      OptionRowLook.dense => ink,
      OptionRowLook.card => Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s4,
        ),
        child: AnimatedContainer(
          duration: MotionGuard.duration(context, AppMotion.fast),
          curve: AppMotion.signature,
          decoration: BoxDecoration(
            color: selected && enabled ? AppColors.brandWash : AppColors.white,
            border: Border.all(
              color: selected && enabled
                  ? AppColors.primary
                  : AppColors.divider,
              width: AppSize.s1,
            ),
            borderRadius: _cardRadius,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: _cardRadius,
            clipBehavior: Clip.antiAlias,
            child: ink,
          ),
        ),
      ),
    };
    return MergeSemantics(
      child: Semantics(
        checked: selected,
        inMutuallyExclusiveGroup: true,
        enabled: enabled,
        child: body,
      ),
    );
  }
}
