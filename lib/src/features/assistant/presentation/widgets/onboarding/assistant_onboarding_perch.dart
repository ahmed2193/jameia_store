import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../../../core/responsive/app_size.dart';
import '../mascot/assistant_mascot.dart';
import '../mascot/assistant_mascot_mood.dart';

/// The mascot sitting on the tour's top edge, alive the whole way: it drops
/// in with a bounce as the sheet opens, wears the face the demos ask for
/// ([mood], a hop whenever [cheer] changes), leans the way the pages are
/// dragged, follows the customer's finger with its eyes ([touches]) and
/// giggles when tapped. Decorative for screen readers.
class AssistantOnboardingPerch extends StatefulWidget {
  const AssistantOnboardingPerch({
    super.key,
    required this.mood,
    required this.cheer,
    required this.pages,
    required this.touches,
  });

  static const double size = AppSize.s96;

  final AssistantMascotMood mood;
  final Object? cheer;

  /// The tour's pages: a drag between two of them tilts the mascot.
  final PageController pages;

  /// Global positions of the customer's finger over the tour.
  final ValueListenable<Offset?> touches;

  @override
  State<AssistantOnboardingPerch> createState() =>
      _AssistantOnboardingPerchState();
}

class _AssistantOnboardingPerchState extends State<AssistantOnboardingPerch>
    with SingleTickerProviderStateMixin {
  static const double _dropFrom = -AppSize.s64;

  /// Tilt (radians) and sideways shift at a full page of drag.
  static const double _tilt = 0.5;
  static const double _shift = AppSize.s16;
  static const double _lookReach = 200;

  /// The gaze moves only for a real change of where to look.
  static const double _lookStep = 0.15;
  static const Duration _lookHold = Duration(milliseconds: 1200);
  static const Duration _giggleHold = Duration(milliseconds: 900);
  static final SpringCurve _drop = SpringCurve(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 240, ratio: 0.5),
  );

  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: _drop.duration,
  );
  final GlobalKey _face = GlobalKey();

  Offset _look = Offset.zero;
  AssistantMascotMood? _giggle;
  int _giggles = 0;
  bool _landed = false;
  Timer? _lookTimer;
  Timer? _giggleTimer;

  @override
  void initState() {
    super.initState();
    widget.touches.addListener(_glance);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_landed) return;
    _landed = true;
    if (MotionGuard.reduced(context)) {
      _arrival.value = 1;
    } else {
      _arrival.forward();
    }
  }

  @override
  void didUpdateWidget(AssistantOnboardingPerch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.touches != widget.touches) {
      oldWidget.touches.removeListener(_glance);
      widget.touches.addListener(_glance);
    }
  }

  /// Eyes on the finger for a moment.
  void _glance() {
    final touch = widget.touches.value;
    final box = _face.currentContext?.findRenderObject();
    if (touch == null || box is! RenderBox || !box.attached) return;
    final delta = touch - box.localToGlobal(box.size.center(Offset.zero));
    if (delta.distance < AssistantOnboardingPerch.size / 2) return;
    final reach = (delta.distance / _lookReach).clamp(0.0, 1.0);
    final look = delta / delta.distance * reach;
    if ((look - _look).distance < _lookStep) return;
    setState(() => _look = look);
    _lookTimer?.cancel();
    _lookTimer = Timer(_lookHold, () {
      if (mounted) setState(() => _look = Offset.zero);
    });
  }

  void _onTap() {
    Haptics.tap();
    _giggleTimer?.cancel();
    setState(() {
      _giggle = AssistantMascotMood.happy;
      _giggles++;
    });
    _giggleTimer = Timer(_giggleHold, () {
      if (mounted) setState(() => _giggle = null);
    });
  }

  @override
  void dispose() {
    widget.touches.removeListener(_glance);
    _lookTimer?.cancel();
    _giggleTimer?.cancel();
    _arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forward = Directionality.of(context) == TextDirection.ltr ? 1 : -1;
    return AnimatedBuilder(
      animation: Listenable.merge([_arrival, widget.pages]),
      builder: (context, mascot) {
        final pages = widget.pages;
        final page = pages.hasClients ? pages.page ?? 0.0 : 0.0;
        final lean = (page - page.roundToDouble()) * forward;
        final landed = _drop.transform(_arrival.value);
        return Transform.translate(
          offset: Offset(lean * _shift, (1 - landed) * _dropFrom),
          child: Transform.rotate(
            angle: lean * _tilt,
            alignment: Alignment.bottomCenter,
            child: mascot,
          ),
        );
      },
      child: GestureDetector(
        onTap: _onTap,
        excludeFromSemantics: true,
        child: AssistantMascot(
          key: _face,
          size: AssistantOnboardingPerch.size,
          outlined: true,
          mood: _giggle ?? widget.mood,
          look: _look,
          cheer: (widget.cheer, _giggles),
        ),
      ),
    );
  }
}
