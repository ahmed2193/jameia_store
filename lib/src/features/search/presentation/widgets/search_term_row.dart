import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/press_scale.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/press_row.dart';
import 'search_highlighted_text.dart';

/// A past search that matches the typed text: the clock icon, the term with
/// the typed part in bold and, at the end, the arrow that copies the term
/// into the field to refine it (it points at the field's start, so it
/// mirrors in RTL). The rest of the row searches for the term.
class SearchTermRow extends StatelessWidget {
  const SearchTermRow({
    super.key,
    required this.term,
    required this.query,
    required this.onTap,
    required this.onRefine,
  });

  final String term;
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRefine;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return PressRow(
      onTap: onTap,
      // The term below carries the row's action for screen readers, so the
      // refine arrow stays a separate button.
      excludeFromSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSize.s56),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.gutter,
            end: AppSpacing.s4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: term,
                  onTap: onTap,
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: AppSize.s24,
                        color: AppColors.secondaryText,
                      ),
                      const SizedBox(width: AppSpacing.s16),
                      Expanded(
                        child: SearchHighlightedText(
                          text: term,
                          query: query,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Presses itself; the row stays still then.
              PressScale(
                pressedScale: AppMotion.pressedScaleSmall,
                child: IconButton(
                  tooltip: 'search.refine_term'.tr(namedArgs: {'term': term}),
                  onPressed: onRefine,
                  style: IconButton.styleFrom(
                    fixedSize: const Size.square(AppSize.s48),
                  ),
                  icon: Icon(
                    rtl ? Icons.north_east_rounded : Icons.north_west_rounded,
                    size: AppSize.s20,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
