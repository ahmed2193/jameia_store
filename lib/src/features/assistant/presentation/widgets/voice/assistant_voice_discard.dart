import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import 'assistant_voice_bin_painter.dart';

/// WhatsApp's goodbye to a cancelled recording: the red mic hops up and
/// flips, a bin rises under it and opens, the mic drops in, the lid shuts
/// and the bin sinks away. Played once over the start of the message box,
/// then [onDone] — in [AppMotion.slow] (docs/motion §9.6 §2.9, approval
/// #13), and without covering the box: it paints no background and takes no
/// touch, so the field under it is usable at once. The composer skips it
/// under reduced motion.
class AssistantVoiceDiscard extends StatefulWidget {
  const AssistantVoiceDiscard({super.key, required this.onDone});

  final VoidCallback onDone;

  static const Duration duration = AppMotion.slow;

  @override
  State<AssistantVoiceDiscard> createState() => _AssistantVoiceDiscardState();
}

class _AssistantVoiceDiscardState extends State<AssistantVoiceDiscard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AssistantVoiceDiscard.duration,
  );

  // The choreography, as shares of [AssistantVoiceDiscard.duration].
  static const Interval _hop = Interval(0, 0.3, curve: AppMotion.signature);
  static const Interval _binRise = Interval(
    0.1,
    0.35,
    curve: AppMotion.signature,
  );
  static const Interval _lidOpen = Interval(
    0.3,
    0.42,
    curve: AppMotion.signature,
  );
  static const Interval _fall = Interval(0.35, 0.62, curve: AppMotion.exit);
  static const Interval _micFade = Interval(0.5, 0.62);
  static const Interval _lidClose = Interval(
    0.62,
    0.72,
    curve: AppMotion.signature,
  );
  static const Interval _binSink = Interval(0.78, 1, curve: AppMotion.exit);

  static const double _hopHeight = AppSize.s36;
  static const double _dropDepth = AppSize.s6;
  static const double _binTravel = AppSize.s24;
  static const double _openAngle = -0.9;
  static const double _fallenScale = 0.5;
  static const Size _binSize = Size(AppSize.s20, AppSize.s24);

  /// The bin sits under the mic, which starts where the hold bar's was.
  static const double _micStart = AppSpacing.s12;
  static const double _binStart = AppSpacing.s12 + AppSize.s1;

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final hop = _hop.transform(t);
          final fall = _fall.transform(t);
          final rise = _binRise.transform(t);
          final sink = _binSink.transform(t);
          final lid =
              _openAngle * (_lidOpen.transform(t) - _lidClose.transform(t));
          return Stack(
            clipBehavior: Clip.none,
            alignment: AlignmentDirectional.centerStart,
            children: [
              PositionedDirectional(
                start: _binStart,
                child: Opacity(
                  opacity: rise * (1 - sink),
                  child: Transform.translate(
                    offset: Offset(0, _binTravel * (1 - rise + sink)),
                    child: CustomPaint(
                      size: _binSize,
                      painter: AssistantVoiceBinPainter(
                        lidAngle: lid,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: _micStart,
                child: Opacity(
                  opacity: 1 - _micFade.transform(t),
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      -_hopHeight * hop + (_hopHeight + _dropDepth) * fall,
                    ),
                    child: Transform.rotate(
                      angle: math.pi * hop,
                      child: Transform.scale(
                        scale: 1 - (1 - _fallenScale) * fall,
                        child: const HeroIcon(
                          HeroIcons.mic,
                          size: AppSize.s22,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
