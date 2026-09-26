import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/haptics.dart';
import '../motion/motion.dart';
import '../responsive/app_size.dart';

/// A row of underline tabs ("All | Snacks & Chocolate | Ice Cream"): the
/// open tab reads in ink with an ink bar under it that glides to the tab
/// picked next, while the row slides that tab into view. The others read in
/// grey. Taps click softly.
class CollectionTabStrip extends StatefulWidget {
  const CollectionTabStrip({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  static const double height = AppSize.s48;

  @override
  State<CollectionTabStrip> createState() => _CollectionTabStripState();
}

class _CollectionTabStripState extends State<CollectionTabStrip> {
  static const double _barHeight = AppSize.s2;
  static const double _centered = 0.5;

  final GlobalKey _row = GlobalKey();
  List<GlobalKey> _tabs = const [];

  /// Where the ink bar sits: start offset and width, from the reading start.
  (double, double)? _bar;

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(CollectionTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length) _syncKeys();
    if (oldWidget.selected != widget.selected) {
      _revealSelected(glide: true);
    } else if (oldWidget.labels != widget.labels) {
      // New names, new widths: the bar is measured again, in place.
      _revealSelected(glide: false);
    }
  }

  void _syncKeys() {
    _tabs = List<GlobalKey>.generate(widget.labels.length, (_) => GlobalKey());
  }

  /// Measures the open tab and slides the row so it is in view.
  void _revealSelected({required bool glide}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.selected >= _tabs.length) return;
      final tab = _tabs[widget.selected].currentContext;
      final row = _row.currentContext?.findRenderObject();
      final box = tab?.findRenderObject();
      if (tab == null || row is! RenderBox || box is! RenderBox) return;
      final left = box.localToGlobal(Offset.zero, ancestor: row).dx;
      final width = box.size.width;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final start = rtl ? row.size.width - left - width : left;
      if (_bar != (start, width)) setState(() => _bar = (start, width));
      Scrollable.of(tab).position.ensureVisible(
        box,
        alignment: _centered,
        duration: glide && !MotionGuard.reduced(context)
            ? AppMotion.page
            : Duration.zero,
        curve: AppMotion.emphasizedDecelerate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bar == null) _revealSelected(glide: false);
    final duration = MotionGuard.duration(context, AppMotion.medium);
    final bar = _bar;
    return SizedBox(
      height: CollectionTabStrip.height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s4,
        ),
        child: Stack(
          key: _row,
          children: [
            Row(
              children: [
                for (var i = 0; i < widget.labels.length; i++)
                  Semantics(
                    key: _tabs[i],
                    button: true,
                    selected: i == widget.selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i == widget.selected) return;
                        Haptics.selection();
                        widget.onSelected(i);
                      },
                      child: Container(
                        height: CollectionTabStrip.height,
                        alignment: Alignment.center,
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpacing.s12,
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontSize: AppSize.font15,
                            color: i == widget.selected
                                ? AppColors.primaryText
                                : AppColors.secondaryText,
                            fontWeight: i == widget.selected
                                ? AppTextStyles.medium
                                : AppTextStyles.regular,
                          ),
                          child: Text(widget.labels[i], maxLines: 1),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (bar != null)
              AnimatedPositionedDirectional(
                duration: duration,
                curve: AppMotion.emphasizedDecelerate,
                start: bar.$1,
                width: bar.$2,
                bottom: 0,
                height: _barHeight,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryText,
                    borderRadius: BorderRadius.all(
                      Radius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
