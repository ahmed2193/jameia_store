import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/second_clock.dart';
import '../motion/second_clock_scope.dart';
import '../responsive/app_size.dart';

/// "Ends in 02:14:33" for a flash sale: an ink chip that ticks every second
/// until [endsAt], then disappears. The clock reads left to right in Arabic
/// too.
///
/// It ticks on the nearest `SecondClockScope`'s clock, so N chips on a page
/// cost one timer and one frame a second, aligned (docs/motion PB-06). A chip
/// with no scope above it owns one [SecondClock] of its own. Either way the
/// clock rests while the page is behind another, and the chip lets go of it
/// once the sale ends.
class CountdownChip extends StatefulWidget {
  const CountdownChip({
    super.key,
    required this.endsAt,
    this.clock = DateTime.now,
  });

  final DateTime endsAt;

  /// What time it is when the chip owns its clock (no scope); a test sets it.
  /// Under a scope, the scope's clock rules.
  final DateTime Function() clock;

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  static const double _glyph = AppSize.s16;
  static const int _pad = 2;

  /// The scope's clock, or [_own].
  SecondClock? _clock;

  /// Only without a scope: this chip's own clock.
  SecondClock? _own;
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clock ??=
        SecondClockScope.maybeOf(context) ??
        (_own = SecondClock(clock: widget.clock));
    // A scope rests its clock by itself; an own clock follows the page.
    _own?.enabled = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didUpdateWidget(CountdownChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endsAt != oldWidget.endsAt) _sync();
  }

  @override
  void dispose() {
    _detach();
    _own?.dispose();
    super.dispose();
  }

  Duration get _left => widget.endsAt.difference(_clock?.now ?? widget.clock());

  /// Listens while the sale runs; lets go at zero.
  void _sync() {
    final clock = _clock;
    if (clock == null) return;
    final run = _left > Duration.zero;
    if (run && !_listening) {
      clock.addListener(_onTick);
      _listening = true;
    } else if (!run) {
      _detach();
    }
  }

  void _detach() {
    if (!_listening) return;
    _clock?.removeListener(_onTick);
    _listening = false;
  }

  void _onTick() {
    if (!mounted) return;
    if (_left <= Duration.zero) _detach();
    setState(() {});
  }

  static String _two(int value) => '$value'.padLeft(_pad, '0');

  @override
  Widget build(BuildContext context) {
    final left = _left;
    if (left <= Duration.zero) return const SizedBox.shrink();
    final clock =
        '${_two(left.inHours)}:${_two(left.inMinutes % Duration.minutesPerHour)}'
        ':${_two(left.inSeconds % Duration.secondsPerMinute)}';
    final style = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.white,
      fontWeight: AppTextStyles.bold,
      fontFeatures: const [ui.FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryText,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_outlined,
            size: _glyph,
            color: AppColors.white,
          ),
          const SizedBox(width: AppSpacing.s6),
          Flexible(
            child: Text(
              'core.ends_in'.tr(
                namedArgs: {'time': '${Unicode.LRI}$clock${Unicode.PDI}'},
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
