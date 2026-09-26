import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../responsive/app_size.dart';

/// "Ends in 02:14:33" for a flash sale: an ink chip that ticks every second
/// until [endsAt], then disappears. The clock reads left to right in Arabic
/// too, and rests while its page is behind another.
class CountdownChip extends StatefulWidget {
  const CountdownChip({
    super.key,
    required this.endsAt,
    this.clock = DateTime.now,
  });

  final DateTime endsAt;

  /// What time it is; a test sets it.
  final DateTime Function() clock;

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  static const Duration _tick = Duration(seconds: 1);
  static const double _glyph = AppSize.s16;
  static const int _pad = 2;

  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    if (!TickerMode.valuesOf(context).enabled || _left <= Duration.zero) {
      return;
    }
    _timer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {});
      if (_left <= Duration.zero) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration get _left => widget.endsAt.difference(widget.clock());

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
