import 'package:flutter/material.dart';

import '../motion/motion.dart';
import 'hero_money_text.dart';

/// A bottom-bar total that never names a stale amount: [kd] null shows
/// [placeholder] ("Updating…", "—"); the amount stays mounted underneath,
/// held at the last value shown, so when the new total lands its digits roll
/// from the old amount to the new one (a freshly mounted roller would be
/// static). Cross-fade over [AppMotion.fast]; reduced motion → instant swap.
/// Only the amount is read out.
class HeroBarTotal extends StatefulWidget {
  const HeroBarTotal({
    super.key,
    required this.kd,
    required this.placeholder,
    required this.style,
    this.placeholderStyle,
    this.alignment = AlignmentDirectional.centerEnd,
  });

  final double? kd;
  final String placeholder;
  final TextStyle style;
  final TextStyle? placeholderStyle;

  /// Where the shorter of amount and placeholder sits: the end of a total
  /// row, the start of a basket summary.
  final AlignmentDirectional alignment;

  @override
  State<HeroBarTotal> createState() => _HeroBarTotalState();
}

class _HeroBarTotalState extends State<HeroBarTotal> {
  static const double _shown = 1;

  late double? _held = widget.kd;

  @override
  void didUpdateWidget(HeroBarTotal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final kd = widget.kd;
    if (kd != null) _held = kd;
  }

  @override
  Widget build(BuildContext context) {
    final held = _held;
    final pending = widget.kd == null;
    final duration = MotionGuard.duration(context, AppMotion.fast);
    return Stack(
      alignment: widget.alignment,
      children: <Widget>[
        if (held != null)
          AnimatedOpacity(
            opacity: pending ? 0 : _shown,
            duration: duration,
            child: ExcludeSemantics(
              excluding: pending,
              child: HeroMoneyText(
                kd: held,
                rolling: true,
                style: widget.style,
              ),
            ),
          ),
        AnimatedOpacity(
          opacity: pending ? _shown : 0,
          duration: duration,
          child: ExcludeSemantics(
            excluding: !pending,
            child: Text(
              widget.placeholder,
              maxLines: 1,
              style: widget.placeholderStyle ?? widget.style,
            ),
          ),
        ),
      ],
    );
  }
}
