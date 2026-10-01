import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/entrance_cascade_item.dart';
import '../motion/haptics.dart';
import '../motion/pop_scale.dart';
import '../responsive/app_size.dart';
import 'app_button.dart';
import 'hero_secondary_button.dart';
import 'state_icon_plate.dart';

/// The one confirmation dialog (docs/design_system.md §5): a white card with
/// the screen's [art] (a mascot scene) or an [icon] plate, a bold [title],
/// the grey [message] and an optional [note], then the [confirmLabel] pill —
/// red when [destructive] — over a white outlined [cancelLabel] pill. Pops
/// `true` on confirm, `false` on cancel (a barrier tap answers `null`) —
/// its own route, so it closes through its [Navigator] whether or not a
/// router sits above it. Present it with `showHeroConfirmDialog`.
///
/// It arrives like the home popups: the card pops in on a spring (the
/// route), the art pops after it and the words and buttons rise in one after
/// the other. Reduced motion: everything in place. A destructive confirm
/// fires the one warning haptic, on the confirm only.
class HeroConfirmDialog extends StatelessWidget {
  const HeroConfirmDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.message,
    this.note,
    this.icon,
    this.art,
    this.cancelLabel,
    this.destructive = false,
  });

  static const double _maxWidth = AppSize.s350;
  static const double _plate = AppSize.s64;
  static const double _plateGlyph = AppSize.s28;

  /// The plate grows from here on the spring that pops [PopScale].
  static const double _artFrom = 0.6;

  final String title;
  final String confirmLabel;
  final String? message;

  /// A smaller grey line under the message (what happens meanwhile).
  final String? note;

  /// The plate glyph when there is no [art].
  final IconData? icon;

  /// A composed illustration in place of the plate.
  final Widget? art;

  /// Defaults to `common.cancel`.
  final String? cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    final drawn =
        art ??
        (glyph == null
            ? null
            : StateIconPlate(
                icon: glyph,
                dimension: _plate,
                iconSize: _plateGlyph,
                color: destructive ? AppColors.errorDeep : AppColors.brandDeep,
                fill: destructive ? AppColors.errorBg : AppColors.brandLightBg,
              ));
    final body = message;
    final aside = note;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Semantics(
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.s24,
                  AppSpacing.s28,
                  AppSpacing.s24,
                  AppSpacing.s16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (drawn != null) ...[
                      PopScale.onMount(from: _artFrom, child: drawn),
                      const SizedBox(height: AppSpacing.s16),
                    ],
                    EntranceCascadeItem.single(
                      index: 1,
                      child: Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.groupTitle,
                        ),
                      ),
                    ),
                    if (body != null && body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      EntranceCascadeItem.single(
                        index: 2,
                        child: Text(
                          body,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.itemTitle.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                    if (aside != null && aside.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s8),
                      EntranceCascadeItem.single(
                        index: 2,
                        child: Text(
                          aside,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.meta,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                    EntranceCascadeItem.single(
                      index: 3,
                      child: AppButton(
                        label: confirmLabel,
                        color: destructive ? AppColors.errorDeep : null,
                        foreground: destructive ? AppColors.white : null,
                        // A destructive confirm: the one warning haptic.
                        haptic: destructive
                            ? HapticKind.warning
                            : HapticKind.tap,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    EntranceCascadeItem.single(
                      index: 4,
                      child: HeroSecondaryButton(
                        label: cancelLabel ?? 'common.cancel'.tr(),
                        expanded: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
