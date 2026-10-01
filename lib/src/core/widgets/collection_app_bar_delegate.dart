import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../design/hero_icons.dart';
import '../responsive/app_size.dart';
import 'round_outlined_button.dart';

/// The pinned top bar of a collection page, status bar included: a round
/// back button, the store's name, a round search button. It wears the
/// hero's warm tint while the hero shows and turns white as the hero scrolls
/// away ([progress] 0 → 1), so the band and the bar read as one piece.
class CollectionAppBarDelegate extends SliverPersistentHeaderDelegate {
  const CollectionAppBarDelegate({
    required this.topInset,
    required this.title,
    required this.progress,
    required this.onSearch,
    required this.backLabel,
    required this.searchLabel,
    this.onBack,
    this.tint = AppColors.collectionCream,
    this.showsHairline = false,
  });

  /// The status bar's height: the bar paints under it.
  final double topInset;
  final String title;

  /// How far the hero has scrolled away (0 = in full view, 1 = gone).
  final ValueNotifier<double> progress;
  final VoidCallback onSearch;
  final String backLabel;
  final String searchLabel;

  /// Null on a page with nothing to go back to: no back button.
  final VoidCallback? onBack;
  final Color tint;

  /// A hairline under the white bar (for a page with no pinned tabs).
  final bool showsHairline;

  static const double barHeight = AppSize.s64;

  @override
  double get maxExtent => topInset + barHeight;

  @override
  double get minExtent => maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final onBack = this.onBack;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, p, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: Color.lerp(tint, AppColors.white, p),
            border: showsHairline && p >= 1
                ? const Border(bottom: BorderSide(color: AppColors.divider))
                : null,
          ),
          child: child,
        ),
        // A pinned header must fill its extent.
        child: SizedBox(
          height: maxExtent,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: topInset,
              start: AppSpacing.s16,
              end: AppSpacing.s16,
            ),
            child: Row(
              children: [
                if (onBack != null) ...[
                  RoundOutlinedButton(
                    icon: HeroIcons.back,
                    label: backLabel,
                    onTap: onBack,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subheadingLarge.copyWith(
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                RoundOutlinedButton(
                  icon: HeroIcons.search,
                  label: searchLabel,
                  onTap: onSearch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(CollectionAppBarDelegate oldDelegate) =>
      oldDelegate.topInset != topInset ||
      oldDelegate.title != title ||
      oldDelegate.progress != progress ||
      oldDelegate.onBack != onBack ||
      oldDelegate.onSearch != onSearch ||
      oldDelegate.tint != tint ||
      oldDelegate.showsHairline != showsHairline ||
      oldDelegate.backLabel != backLabel ||
      oldDelegate.searchLabel != searchLabel;
}
