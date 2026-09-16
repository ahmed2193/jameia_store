import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/keeta_image.dart';

/// Fixed horizontal rank rail above the section list. Only shown when there is
/// more than one rank. Pinned (a real row) so nothing slides under it.
///
/// ── Per-scroll-tick rebuild fix ─────────────────────────────────────────────
/// The rail's selected highlight reads [activeRank] (the [ShopMenuCubit]'s
/// `activeRank` notifier) through a [ValueListenableBuilder] wrapped around EACH
/// item ([RankRailItem]), so when the active index flips a→b only those two
/// items rebuild — never the whole [ListView], never on a `setState`. The
/// scroll-position listener calls `cubit.reportActiveRank(i)` which updates the
/// notifier; the rail builder itself never rebuilds during a body scroll.
class RankRail extends StatelessWidget {
  const RankRail({
    super.key,
    required this.sections,
    required this.hasImages,
    required this.activeRank,
    required this.controller,
    required this.itemExtent,
    required this.onSelect,
  });

  final List<MenuSection> sections;
  final bool hasImages;
  final ValueListenable<int> activeRank;
  final ScrollController controller;
  final double itemExtent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: hasImages ? 108 : 52,
      color: AppColors.white,
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s6),
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8,
        ),
        itemExtent: itemExtent,
        itemCount: sections.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, i) {
          // Each item subscribes to [activeRank] itself, so only the two items
          // whose selected-state flips rebuild — never the whole list.
          return RepaintBoundary(
            child: ValueListenableBuilder<int>(
              valueListenable: activeRank,
              builder: (context, active, _) {
                return RankRailItem(
                  key: ValueKey('rank_rail_${i}_${sections[i].id}'),
                  section: sections[i],
                  selected: i == active,
                  hasImages: hasImages,
                  onTap: () => onSelect(i),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// One rail item — circular image with a Keeta-yellow selected ring + glow and
/// a title below (Keeta restyle of jm3eia's `_RankNavItem` scale/elastic anim).
class RankRailItem extends StatefulWidget {
  const RankRailItem({
    super.key,
    required this.section,
    required this.selected,
    required this.hasImages,
    required this.onTap,
  });

  final MenuSection section;
  final bool selected;
  final bool hasImages;
  final VoidCallback onTap;

  @override
  State<RankRailItem> createState() => _RankRailItemState();
}

class _RankRailItemState extends State<RankRailItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Same pop language as core PopScale: emphasized (overshoot) enter on
    // [AppMotion.medium], paired [AppMotion.exit] shrink on [AppMotion.fast].
    _spring = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
      reverseDuration: AppMotion.fast,
    );
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _spring,
        curve: AppMotion.emphasized, // overshoot pop on activate
        reverseCurve: AppMotion.exit, // smooth shrink on deactivate
      ),
    );
    if (widget.selected) _spring.value = 1.0;
  }

  @override
  void didUpdateWidget(RankRailItem old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    if (widget.selected) {
      _spring.forward(from: 0.0);
    } else {
      _spring.reverse();
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.hasImages ? 78 : 92,
          margin: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.hasImages) ...[
                AnimatedContainer(
                  duration: MotionGuard.duration(context, AppMotion.fast),
                  curve: MotionGuard.curve(context, AppMotion.standard),
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.divider,
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.30),
                              blurRadius: AppRadius.r5,
                              spreadRadius: 1,
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: ClipOval(
                    child: AnimatedScale(
                      scale: selected ? 1.08 : 1.0,
                      duration: MotionGuard.duration(context, AppMotion.fast),
                      curve: MotionGuard.curve(context, AppMotion.standard),
                      child: KeetaImage(
                        url: widget.section.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
              if (!widget.hasImages)
                AnimatedContainer(
                  duration: MotionGuard.duration(context, AppMotion.fast),
                  curve: MotionGuard.curve(context, AppMotion.standard),
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.smallBackground,
                    borderRadius: BorderRadius.circular(AppRadius.r5),
                  ),
                  child: Text(
                    widget.section.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: selected
                          ? AppTextStyles.bold
                          : AppTextStyles.regular,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: 76,
                  child: AnimatedDefaultTextStyle(
                    duration: MotionGuard.duration(context, AppMotion.fast),
                    curve: MotionGuard.curve(context, AppMotion.standard),
                    style: AppTextStyles.captionMedium.copyWith(
                      fontSize: AppSize.font11,
                      height: 1.2,
                      fontWeight: selected
                          ? AppTextStyles.bold
                          : AppTextStyles.medium,
                      color: selected
                          ? AppColors.primary
                          : AppColors.primaryText,
                    ),
                    child: Text(
                      widget.section.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
