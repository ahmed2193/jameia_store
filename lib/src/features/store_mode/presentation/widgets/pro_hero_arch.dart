import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import 'pro_arch_painter.dart';
import 'pro_hero_bag.dart';
import 'pro_hero_tone.dart';
import 'pro_spark_painter.dart';

/// Bottom of the hero band: the Hero bag inside an outlined dome, with a
/// spark doodle at the dome's top-start corner. The dome's foot meets the
/// band's bottom edge.
///
/// On first show the outline draws itself from both feet up to the crown
/// while the dome fills in, then the spark strokes pop out one by one. A new
/// [tone] (another plan) only recolours the drawn arch — outline and fill
/// blend into the new colours over [AppMotion.medium] — it never draws
/// itself again (backlog B2-03: one quiet change per plan switch). A soft glow breathes behind the bag. Reduced motion → drawn at once.
class ProHeroArch extends StatefulWidget {
  const ProHeroArch({super.key, required this.tone});

  final ProHeroTone tone;

  @override
  State<ProHeroArch> createState() => _ProHeroArchState();
}

class _ProHeroArchState extends State<ProHeroArch>
    with TickerProviderStateMixin {
  static const double _height = AppSize.s220;
  static const double _stroke = AppSize.s8;
  static const double _sparkSide = AppSize.s40;
  static const double _sparkStroke = AppSize.s6;
  static const double _glow = AppSize.s200;
  static const double _glowMinOpacity = 0.3;
  static const double _glowMaxOpacity = 0.55;

  /// Where the glow sits: centred, low in the dome (behind the bag).
  static const Alignment _glowAlignment = Alignment(0, 0.7);

  /// The outline draws over [AppMotion.drawOn]; the sparks pop after it.
  static final Duration _total = AppMotion.drawOn + AppMotion.slow;
  static final double _drawShare =
      AppMotion.drawOn.inMilliseconds / _total.inMilliseconds;
  static const double _fillShare = 0.4;
  static const double _sparkStart = 0.5;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );
  late final Animation<double> _draw = CurvedAnimation(
    parent: _controller,
    curve: Interval(0, _drawShare, curve: AppMotion.signature),
  );
  late final AnimationController _recolour = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
  );

  late final CurvedAnimation _recolourCurve = CurvedAnimation(
    parent: _recolour,
    curve: AppMotion.signature,
  );

  /// The fill (and, on a recolour, the outline) blend: first with the
  /// draw, then — for another plan — on its own.
  late final ProxyAnimation _fillIn = ProxyAnimation(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, _fillShare, curve: AppMotion.signature),
    ),
  );
  late final Animation<double> _sparks = CurvedAnimation(
    parent: _controller,
    curve: const Interval(_sparkStart, 1),
  );

  /// The fill the dome blends from: nothing on first show, then the
  /// previous tone's.
  Color? _fromFill;
  Color? _fromStroke;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _play();
  }

  @override
  void didUpdateWidget(ProHeroArch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tone == widget.tone) return;
    _fromFill = oldWidget.tone.archFill;
    _fromStroke = oldWidget.tone.stroke;
    _fillIn.parent = _recolourCurve;
    if (MotionGuard.reduced(context)) {
      _recolour.value = 1;
    } else {
      _recolour.forward(from: 0);
    }
  }

  void _play() {
    if (MotionGuard.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _recolourCurve.dispose();
    _recolour.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone;
    final mirrored = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: _height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ProArchPainter(
                  fill: tone.archFill,
                  fromFill: _fromFill ?? tone.archFill.withValues(alpha: 0),
                  stroke: tone.stroke,
                  fromStroke: _fromStroke,
                  strokeWidth: _stroke,
                  sideInset: AppSpacing.s16,
                  draw: _draw,
                  fillIn: _fillIn,
                ),
              ),
            ),
          ),
          Align(
            alignment: _glowAlignment,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: tone.glow),
              duration: MotionGuard.duration(context, AppMotion.page),
              builder: (context, color, _) => FloatLoop.glow(
                color: color ?? tone.glow,
                diameter: _glow,
                minOpacity: _glowMinOpacity,
                maxOpacity: _glowMaxOpacity,
              ),
            ),
          ),
          const Positioned.fill(child: ProHeroBag(height: _height)),
          PositionedDirectional(
            top: AppSpacing.s4,
            start: AppSpacing.s24,
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size.square(_sparkSide),
                painter: ProSparkPainter(
                  color: tone.stroke,
                  strokeWidth: _sparkStroke,
                  progress: _sparks,
                  mirrored: mirrored,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
