import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../responsive/app_size.dart';
import 'hero_segment.dart';
import 'segmented_thumb_track.dart';

/// The thumb of a [HeroSegmentedControl].
enum HeroSegmentTone {
  /// A dark ink thumb with white labels (settings' language switch).
  dark,

  /// Hero's choice language: a mint thumb with a green hairline, the
  /// chosen label bold deep green and its icon green (checkout's delivery /
  /// pickup switch).
  brandSoft,
}

/// Pill SEGMENTED CONTROL — the language switch in settings, checkout's
/// delivery / pickup, any two-to-four way choice: equal-width segments on
/// the app's one thumb track ([SegmentedThumbTrack]: the thumb slides on the
/// calm spring, mirrors under RTL, jumps under reduced motion, and a
/// selection haptic fires only when the value actually changes). [tone]
/// picks the thumb (see [HeroSegmentTone]); [iconOf] puts an 18 dp glyph
/// before each label.
class HeroSegmentedControl<T> extends StatelessWidget {
  const HeroSegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.height = AppSize.s44,
    this.tone = HeroSegmentTone.dark,
    this.iconOf,
  });

  static const double _inset = AppSpacing.s4;

  static const BorderRadius _pill = BorderRadius.all(
    Radius.circular(AppRadius.pill),
  );

  static const BoxDecoration _darkThumb = BoxDecoration(
    color: AppColors.primaryText,
    borderRadius: _pill,
  );

  static const BoxDecoration _brandSoftThumb = BoxDecoration(
    color: AppColors.brandWash,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.primary, width: AppSize.s1),
    ),
    borderRadius: _pill,
  );

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;

  /// `null` = the whole control is disabled (e.g. while a change runs).
  final ValueChanged<T>? onChanged;
  final double height;
  final HeroSegmentTone tone;

  /// An optional glyph before each label.
  final IconData? Function(T value)? iconOf;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected);
    final change = onChanged;
    final iconOf = this.iconOf;
    return Container(
      height: height,
      padding: const EdgeInsets.all(_inset),
      decoration: const BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: _pill,
      ),
      child: SegmentedThumbTrack(
        count: values.length,
        selected: index,
        thumb: DecoratedBox(
          decoration: tone == HeroSegmentTone.brandSoft
              ? _brandSoftThumb
              : _darkThumb,
        ),
        onSelected: change == null ? null : (i) => change(values[i]),
        segmentBuilder: (context, i, select, _) => HeroSegment(
          label: labelOf(values[i]),
          selected: i == index,
          tone: tone,
          icon: iconOf?.call(values[i]),
          onTap: select,
        ),
      ),
    );
  }
}
